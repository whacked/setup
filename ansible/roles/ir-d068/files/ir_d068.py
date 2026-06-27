#!/usr/bin/env python3
"""Controller for the D068 IR encode/decode serial module (STC11F04E MCU).

The D068 is a small 4-pin serial board (5V / GND / RXD / TXD). Its on-board
STC11F04E MCU does all the IR work; the host just talks to it over a 9600 8N1
serial line. Because it is wired to non-UART GPIOs on this Pi, we drive the
serial link in software through the pigpio daemon (bit-bang serial).

Wiring (Raspberry Pi, BCM GPIO numbering)
-----------------------------------------
    module 5V   -> Pi 5V    (header pin 2 or 4)
    module GND  -> Pi GND   (header pin 6, etc.)
    module TXD  -> Pi GPIO12 (header pin 32)   <- Pi READS decoded IR here
    module RXD  -> Pi GPIO24 (header pin 18)   <- Pi WRITES tx commands here

    NOTE: the module is a 5V device, so its TXD idles/drives at ~5V into the
    3.3V-only GPIO12. It works, but for long-term reliability add a level
    shifter / divider on the module-TXD -> Pi-GPIO12 line. The Pi-3.3V -> 5V
    module-RXD direction is reliable as-is.

Serial protocol (9600 8N1)
--------------------------
    Transmit (encode) -- send 5 bytes:   A1 F1 <user1> <user2> <cmd>
        A1 = device-address header (factory default)
        F1 = "transmit IR" opcode
        user1, user2 = the two IR address/user-code bytes
        cmd          = the command/key byte
    Acknowledgement byte the module returns:
        F1 = transmit OK, F2 = address changed, F3 = baud changed
        (anything else / nothing = not acknowledged)
    Receive (decode) -- the module emits 3 bytes per decoded frame:
        <user1> <user2> <cmd>
    It only decodes NEC-family (38 kHz) remotes; for anything it cannot
    decode it still flashes its LED but emits 00 00 00.

CLI
---
    ir_d068.py transmit A1F107   # raw: send these hex bytes verbatim
    ir_d068.py send 04 FB 07     # send user1 user2 cmd  (wraps in A1 F1 ..)
    ir_d068.py nec 0x04 0x07     # send NEC address+command (computes inverse)
    ir_d068.py monitor           # print decoded IR frames until Ctrl-C
    ir_d068.py recv --timeout 10 # wait up to 10s for one decoded frame
    ir_d068.py selftest          # send a frame and confirm the F1 ACK
"""
import argparse
import sys
import time

try:
    import pigpio
except ImportError:
    sys.exit("ERROR: python3 pigpio module not found (apt install python3-pigpio)")

# Defaults (overridable on the command line)
RX_GPIO = 12       # module TXD -> we read here
TX_GPIO = 24       # module RXD -> we write here
BAUD = 9600
HEADER = 0xA1      # device-address header
OP_TX = 0xF1       # "transmit IR" opcode
ACK_OK = 0xF1
FRAME_GAP = 0.15   # seconds of silence that ends an inbound frame


def connect():
    pi = pigpio.pi()
    if not pi.connected:
        sys.exit("ERROR: cannot reach the pigpio daemon. Start it with: "
                 "sudo systemctl start pigpiod")
    return pi


def _open_reader(pi, gpio):
    try:
        pi.bb_serial_read_close(gpio)
    except pigpio.error:
        pass
    pi.bb_serial_read_open(gpio, BAUD, 8)


def transmit_raw(pi, data, rx_gpio=RX_GPIO, tx_gpio=TX_GPIO, ack_wait=0.3):
    """Send raw bytes out the module's RXD line and return the ACK byte (or None)."""
    _open_reader(pi, rx_gpio)               # listen for the ACK first
    pi.set_mode(tx_gpio, pigpio.OUTPUT)
    pi.wave_clear()
    pi.wave_add_serial(tx_gpio, BAUD, bytes(data))
    wid = pi.wave_create()
    pi.wave_send_once(wid)
    while pi.wave_tx_busy():
        time.sleep(0.002)
    pi.wave_delete(wid)

    ack = bytearray()
    deadline = time.time() + ack_wait
    while time.time() < deadline:
        count, chunk = pi.bb_serial_read(rx_gpio)
        if count:
            ack += chunk
        time.sleep(0.01)
    pi.bb_serial_read_close(rx_gpio)
    return ack[-1] if ack else None


def transmit(pi, user1, user2, cmd, **kw):
    """Send an encode command: A1 F1 user1 user2 cmd. Returns the ACK byte."""
    frame = [HEADER, OP_TX, user1 & 0xFF, user2 & 0xFF, cmd & 0xFF]
    return transmit_raw(pi, frame, **kw)


def monitor(pi, rx_gpio=RX_GPIO, duration=None, show_acks=False):
    """Print decoded IR frames as they arrive until duration elapses / Ctrl-C."""
    _open_reader(pi, rx_gpio)
    buf = bytearray()
    last = time.time()
    start = time.time()
    try:
        while duration is None or time.time() - start < duration:
            count, chunk = pi.bb_serial_read(rx_gpio)
            now = time.time()
            if count:
                buf += chunk
                last = now
            elif buf and now - last > FRAME_GAP:
                frame = bytes(buf)
                buf = bytearray()
                if show_acks or not all(b == 0xFF for b in frame):
                    print(" ".join("%02X" % b for b in frame), flush=True)
            time.sleep(0.02)
    finally:
        pi.bb_serial_read_close(rx_gpio)


def recv_one(pi, rx_gpio=RX_GPIO, timeout=10.0):
    """Block up to `timeout` for one decoded frame; return it as bytes (or None)."""
    _open_reader(pi, rx_gpio)
    buf = bytearray()
    last = None
    deadline = time.time() + timeout
    try:
        while time.time() < deadline:
            count, chunk = pi.bb_serial_read(rx_gpio)
            now = time.time()
            if count:
                buf += chunk
                last = now
            elif buf and last and now - last > FRAME_GAP:
                return bytes(buf)
            time.sleep(0.02)
        return bytes(buf) if buf else None
    finally:
        pi.bb_serial_read_close(rx_gpio)


def _hexbyte(s):
    return int(s, 16)


def main(argv=None):
    p = argparse.ArgumentParser(description="D068 IR module controller")
    p.add_argument("--rx-gpio", type=int, default=RX_GPIO, help="BCM gpio for module TXD (read)")
    p.add_argument("--tx-gpio", type=int, default=TX_GPIO, help="BCM gpio for module RXD (write)")
    sub = p.add_subparsers(dest="cmd", required=True)

    s = sub.add_parser("send", help="send user1 user2 cmd (each hex)")
    s.add_argument("user1", type=_hexbyte)
    s.add_argument("user2", type=_hexbyte)
    s.add_argument("cmd", type=_hexbyte)

    n = sub.add_parser("nec", help="send NEC address command (computes 8-bit inverse)")
    n.add_argument("address", type=lambda x: int(x, 0))
    n.add_argument("command", type=lambda x: int(x, 0))

    r = sub.add_parser("transmit", help="send raw hex bytes verbatim, e.g. A1F10407FB")
    r.add_argument("hexbytes")

    m = sub.add_parser("monitor", help="print decoded IR frames until Ctrl-C")
    m.add_argument("--duration", type=float, default=None)
    m.add_argument("--show-acks", action="store_true")

    rc = sub.add_parser("recv", help="wait for one decoded frame")
    rc.add_argument("--timeout", type=float, default=10.0)

    sub.add_parser("selftest", help="send a frame and confirm the F1 ACK")

    args = p.parse_args(argv)
    pi = connect()
    kw = dict(rx_gpio=args.rx_gpio, tx_gpio=args.tx_gpio)
    try:
        if args.cmd == "send":
            ack = transmit(pi, args.user1, args.user2, args.cmd, **kw)
            print("ACK: %s%s" % ("%02X" % ack if ack is not None else "none",
                                 " (OK)" if ack == ACK_OK else ""))
            return 0 if ack == ACK_OK else 1
        if args.cmd == "nec":
            addr = args.address & 0xFF
            ack = transmit(pi, addr, (~addr) & 0xFF, args.command & 0xFF, **kw)
            print("ACK: %s%s" % ("%02X" % ack if ack is not None else "none",
                                 " (OK)" if ack == ACK_OK else ""))
            return 0 if ack == ACK_OK else 1
        if args.cmd == "transmit":
            data = bytes.fromhex(args.hexbytes)
            ack = transmit_raw(pi, data, **kw)
            print("ACK: %s%s" % ("%02X" % ack if ack is not None else "none",
                                 " (OK)" if ack == ACK_OK else ""))
            return 0 if ack == ACK_OK else 1
        if args.cmd == "monitor":
            monitor(pi, rx_gpio=args.rx_gpio, duration=args.duration, show_acks=args.show_acks)
            return 0
        if args.cmd == "recv":
            frame = recv_one(pi, rx_gpio=args.rx_gpio, timeout=args.timeout)
            if frame is None:
                print("no frame received", file=sys.stderr)
                return 1
            print(" ".join("%02X" % b for b in frame))
            return 0
        if args.cmd == "selftest":
            ack = transmit(pi, 0x04, 0xFB, 0x07, **kw)
            ok = ack == ACK_OK
            print("selftest: sent A1 F1 04 FB 07 -> ACK %s -> %s"
                  % ("%02X" % ack if ack is not None else "none",
                     "PASS" if ok else "FAIL"))
            return 0 if ok else 1
    finally:
        pi.stop()
    return 0


if __name__ == "__main__":
    sys.exit(main())
