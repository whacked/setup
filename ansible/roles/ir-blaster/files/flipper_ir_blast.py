#!/usr/bin/env python3
"""Replay IR signals from a Flipper .ir file through a discrete IR LED on a Pi GPIO.

The IR transmitter is a plain modulated IR LED (no on-board protocol MCU) wired
to GPIO12. GPIO12 is the Pi's hardware-PWM0 channel; raw frames are emitted as a
38 kHz carrier built with pigpio waves (precise mark/space timing).

USAGE
-----
    flipper_ir_blast.py FILE                 list the signals saved in a .ir file
    flipper_ir_blast.py FILE NAME            play the signal called NAME
    flipper_ir_blast.py FILE NAME --loop     play it repeatedly until killed
    flipper_ir_blast.py FILE NAME --repeat 3 play it 3 times

Options: --gpio (default 12), --freq (carrier Hz override), --gap (seconds
between sends), --repeat, --loop.

Diagnostics (no .ir file needed):
    flipper_ir_blast.py --blink              pulse the carrier on/off (IR camera test)
    flipper_ir_blast.py --carrier 3          hold a solid carrier for 3 s
    flipper_ir_blast.py --nec 0x00 0x0C      transmit a NEC frame (sanity-check a receiver)

Requires the pigpio daemon (sudo systemctl start pigpiod) and python3-pigpio.
"""
import argparse
import sys
import time

try:
    import pigpio
except ImportError:
    sys.exit("ERROR: python3 pigpio not found (apt install python3-pigpio)")

TX_GPIO = 12
FREQ = 38000
DUTY = 0.33


def connect():
    pi = pigpio.pi()
    if not pi.connected:
        sys.exit("ERROR: pigpio daemon unreachable (start it: sudo pigpiod)")
    return pi


# --------------------------------------------------------------------------
# .ir file parsing
# --------------------------------------------------------------------------
def parse_flipper_ir(path):
    """Parse a Flipper .ir file into a list of signal dicts.

    Each dict has: name, type ('raw'|'parsed'), freq, data (raw timings) or
    protocol/address/command (parsed).
    """
    sigs, cur = [], None

    def flush():
        if cur and (cur.get("data") or cur.get("protocol")):
            sigs.append(cur)

    with open(path) as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith("#") or ":" not in line:
                continue
            key, val = (x.strip() for x in line.split(":", 1))
            if key == "name":
                flush()
                cur = {"name": val, "type": None, "freq": FREQ, "data": None,
                       "protocol": None, "address": None, "command": None}
            elif cur is None:
                continue
            elif key == "type":
                cur["type"] = val
            elif key == "frequency":
                cur["freq"] = int(val)
            elif key == "data":
                cur["data"] = [int(x) for x in val.split()]
            elif key == "protocol":
                cur["protocol"] = val
            elif key == "address":
                cur["address"] = [int(x, 16) for x in val.split()]
            elif key == "command":
                cur["command"] = [int(x, 16) for x in val.split()]
        flush()
    return sigs


def nec_timings(addr, cmd):
    """Classic NEC frame (us): 9ms/4.5ms leader, LSB-first addr/~addr/cmd/~cmd,
    560us stop mark."""
    t = [9000, 4500]
    for b in (addr & 0xFF, (~addr) & 0xFF, cmd & 0xFF, (~cmd) & 0xFF):
        for i in range(8):
            t.append(560)
            t.append(1690 if (b >> i) & 1 else 560)
    t.append(560)
    return t


def signal_timings(s):
    """Return (timings_us, freq_hz) for a parsed signal dict, or raise."""
    if s.get("data"):
        return s["data"], s["freq"]
    proto = (s.get("protocol") or "").upper()
    if proto == "NEC":
        addr = (s["address"] or [0])[0]
        cmd = (s["command"] or [0])[0]
        return nec_timings(addr, cmd), 38000
    raise ValueError(
        "signal %r is type=%s protocol=%s -- only raw signals and parsed NEC "
        "are supported by this tool" % (s["name"], s.get("type"), s.get("protocol")))


# --------------------------------------------------------------------------
# transmit
# --------------------------------------------------------------------------
def build_pulses(gpio, timings, freq):
    """One continuous pigpio pulse list for a full frame: marks become 38 kHz
    carrier bursts, spaces hold the line low. Seamless -> no inter-segment gaps."""
    mask = 1 << gpio
    cycle = 1_000_000.0 / freq
    on = int(round(cycle * DUTY))
    off = int(round(cycle - on))
    pulses = []
    for i, t in enumerate(timings):
        t = int(t)
        if i % 2 == 0:                              # mark -> carrier burst
            for _ in range(int(round(t / cycle))):
                pulses.append(pigpio.pulse(mask, 0, on))
                pulses.append(pigpio.pulse(0, mask, off))
        else:                                       # space -> idle gap
            pulses.append(pigpio.pulse(0, mask, t))
    return pulses


def send_raw(pi, gpio, timings, freq):
    """Transmit a frame as ONE seamless waveform.

    Earlier this chunked the pulses into 2000-pulse waves and wave_chain()ed
    them. But chunk boundaries land *inside* carrier marks (a mark is ~34
    pulses, so it dominates the pulse count), and any gap pigpio inserts between
    chained waves splits that mark in two -> a corrupted/variable frame. That is
    fatal for checksummed protocols like Mitsubishi AC, which silently drop any
    frame with a single bad bit (hence "works up close, fails farther away").

    A whole frame fits comfortably in one wave (pigpio allows ~12000 pulses /
    ~25000 CBs; a 165 ms AC frame is ~5100 pulses / ~10000 CBs), so emit a
    single wave for a glitch-free, repeatable carrier. Chunk+chain is kept only
    as a fallback for a pathologically long capture that overflows one wave.
    """
    pi.set_mode(gpio, pigpio.OUTPUT)
    pi.write(gpio, 0)
    pi.wave_clear()
    pulses = build_pulses(gpio, timings, freq)

    pi.wave_add_generic(pulses)
    wid = pi.wave_create()                           # one seamless wave
    if wid >= 0:
        pi.wave_send_once(wid)
        while pi.wave_tx_busy():
            time.sleep(0.002)
        pi.wave_delete(wid)
        return

    # Frame too large for a single wave: fall back to chunk + chain.
    pi.wave_clear()
    CHUNK = 2000                                    # under PI_WAVE_MAX_PULSES
    wids = []
    for off in range(0, len(pulses), CHUNK):
        pi.wave_add_generic(pulses[off:off + CHUNK])
        w = pi.wave_create()
        if w >= 0:
            wids.append(w)
    pi.wave_chain(wids)                             # back-to-back (may glitch at seams)
    while pi.wave_tx_busy():
        time.sleep(0.002)
    for w in wids:
        pi.wave_delete(w)


# --------------------------------------------------------------------------
# hardware-PWM carrier (coarse diagnostics)
# --------------------------------------------------------------------------
def carrier_on(pi, gpio, freq):
    pi.hardware_PWM(gpio, freq, int(DUTY * 1_000_000))


def carrier_off(pi, gpio):
    pi.hardware_PWM(gpio, 0, 0)


# --------------------------------------------------------------------------
# operations
# --------------------------------------------------------------------------
def list_signals(path, sigs):
    print("Signals in %s:" % path)
    for s in sigs:
        if s.get("data"):
            d = s["data"]
            extra = "raw  %d Hz  %d edges  ~%d ms" % (s["freq"], len(d), sum(d) // 1000)
        else:
            extra = "parsed  %s  addr=%s cmd=%s" % (
                s.get("protocol"),
                " ".join("%02X" % b for b in (s.get("address") or [])),
                " ".join("%02X" % b for b in (s.get("command") or [])))
        print("  %-20s %s" % (s["name"], extra))
    print("\nPlay one with:  %s %s <name>" % (sys.argv[0], path))


def play(pi, gpio, freq_override, sig, repeat, gap, loop):
    timings, freq = signal_timings(sig)
    if freq_override:
        freq = freq_override
    # Report the carrier we'll actually emit (integer-us pulses, so freq/duty
    # land on the nearest achievable value -- handy when tuning for range).
    cyc = 1_000_000.0 / freq
    on = int(round(cyc * DUTY))
    off = int(round(cyc - on))
    label = "%s (%d edges, carrier %d Hz / %.0f%% duty [on=%dus off=%dus])" % (
        sig["name"], len(timings), 1_000_000.0 / (on + off),
        100.0 * on / (on + off), on, off)
    if loop:
        print("LOOP playing %s every %.2fs. Ctrl-C/kill to stop." % (label, gap), flush=True)
        n = 0
        try:
            while True:
                send_raw(pi, gpio, timings, freq)
                n += 1
                print("sent %s (#%d)" % (sig["name"], n), flush=True)
                time.sleep(gap)
        finally:
            print("LOOP stopped after %d sends" % n, flush=True)
    else:
        for r in range(repeat):
            print("play %s (%d/%d)" % (label, r + 1, repeat), flush=True)
            send_raw(pi, gpio, timings, freq)
            if r + 1 < repeat:
                time.sleep(gap)
        print("done", flush=True)


def run_blink(pi, gpio, freq, on, off):
    print("BLINK: 38kHz carrier on GPIO%d, %.0fms ON / %.0fms OFF, looping. kill to stop."
          % (gpio, on * 1000, off * 1000), flush=True)
    n = 0
    try:
        while True:
            carrier_on(pi, gpio, freq); time.sleep(on)
            carrier_off(pi, gpio); time.sleep(off)
            n += 1
            if n % 5 == 0:
                print("...%d pulses" % n, flush=True)
    finally:
        carrier_off(pi, gpio)


def run_carrier(pi, gpio, freq, secs):
    print("CARRIER: solid 38kHz on GPIO%d for %.1fs" % (gpio, secs), flush=True)
    try:
        carrier_on(pi, gpio, freq); time.sleep(secs)
    finally:
        carrier_off(pi, gpio)


def run_nec(pi, gpio, freq, addr, cmd, repeat, gap, loop):
    t = nec_timings(addr, cmd)
    label = "NEC addr=0x%02X cmd=0x%02X" % (addr, cmd)
    if loop:
        print("%s looping every %.2fs. kill to stop." % (label, gap), flush=True)
        n = 0
        while True:
            send_raw(pi, gpio, t, freq); n += 1
            if n % 5 == 0:
                print("...%d frames" % n, flush=True)
            time.sleep(gap)
    for r in range(repeat):
        print("%s (%d/%d)" % (label, r + 1, repeat), flush=True)
        send_raw(pi, gpio, t, freq)
        time.sleep(gap)


# --------------------------------------------------------------------------
def main(argv=None):
    global DUTY
    p = argparse.ArgumentParser(
        description="Replay IR signals from a Flipper .ir file via a GPIO IR LED.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="examples:\n"
               "  %(prog)s Room_ac.ir                 # list signals\n"
               "  %(prog)s Room_ac.ir Cycle_cold      # play one\n"
               "  %(prog)s Room_ac.ir Cycle_cold --loop")
    p.add_argument("irfile", nargs="?", help="path to a Flipper .ir file")
    p.add_argument("name", nargs="?", default=None,
                   help="name of the signal to play (omit to list)")
    p.add_argument("--gpio", type=int, default=TX_GPIO)
    p.add_argument("--freq", type=int, default=None, help="override carrier Hz")
    p.add_argument("--duty", type=float, default=None,
                   help="override carrier duty cycle 0-1 (default %.2f); higher = "
                        "more optical power/range, up to ~0.5" % DUTY)
    p.add_argument("--repeat", type=int, default=1)
    p.add_argument("--gap", type=float, default=0.2, help="seconds between sends")
    p.add_argument("--loop", action="store_true", help="repeat until killed")
    # diagnostics (no file needed)
    p.add_argument("--blink", action="store_true", help="pulse carrier on/off (IR camera test)")
    p.add_argument("--carrier", type=float, metavar="SECS", help="solid carrier for N seconds")
    p.add_argument("--nec", nargs=2, metavar=("ADDR", "CMD"), help="send a NEC frame, e.g. --nec 0x00 0x0C")
    p.add_argument("--on", type=float, default=0.25, help="blink on-time (s)")
    p.add_argument("--off", type=float, default=0.25, help="blink off-time (s)")

    args = p.parse_args(argv)
    if args.duty is not None:
        DUTY = args.duty
    pi = connect()
    try:
        if args.blink:
            run_blink(pi, args.gpio, args.freq or FREQ, args.on, args.off); return 0
        if args.carrier is not None:
            run_carrier(pi, args.gpio, args.freq or FREQ, args.carrier); return 0
        if args.nec is not None:
            run_nec(pi, args.gpio, args.freq or FREQ, int(args.nec[0], 0), int(args.nec[1], 0),
                    args.repeat, args.gap, args.loop); return 0
        if not args.irfile:
            p.error("an .ir FILE is required (or use --blink / --carrier / --nec)")
        sigs = parse_flipper_ir(args.irfile)
        if not sigs:
            sys.exit("no signals found in %s" % args.irfile)
        if not args.name:
            list_signals(args.irfile, sigs); return 0
        match = [s for s in sigs if s["name"] == args.name]
        if not match:
            sys.exit("signal %r not found. Available: %s"
                     % (args.name, ", ".join(s["name"] for s in sigs)))
        play(pi, args.gpio, args.freq, match[0], args.repeat, args.gap, args.loop)
        return 0
    finally:
        carrier_off(pi, args.gpio)
        pi.stop()


if __name__ == "__main__":
    sys.exit(main())
