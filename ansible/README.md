# Raspberry Pi / single-board-computer provisioning

Provisions a fleet of mixed boards (Pi Zero / Zero W / Zero 2 W, Pi 3, Pi 4, and
Pi-compatible boards such as the Libre Computer Renegade) running different OS
releases (buster / bullseye / bookworm), from one data-driven playbook.

## Running it

Copy `inventory/example.ini` to a real per-network file (e.g. `inventory/home.ini`),
set the `ansible_host` IPs, then:

```sh
ansible-playbook -i inventory/home.ini site.yml
```

Switching networks = switching the `-i` file. Limit to one board with `-l`:

```sh
ansible-playbook -i inventory/home.ini site.yml -l example-zero2w
```

## How it's organized

Three layers, separated so each thing changes in exactly one place:

| Concern | Where | Changes when |
| --- | --- | --- |
| **Address** (IP) | `inventory/<network>.ini` | the board moves to another network |
| **Identity** (model + capabilities) | `host_vars/<host>.yml` | a HAT/sensor is added or removed |
| **OS release & CPU arch** | Ansible facts (auto) | never declared — re-imaging just works |

- `inventory/<network>.ini` — one file per network. Same host names recur across
  files with that network's IPs. Copy `example.ini` to add a network and change
  only the `ansible_host` values. (Real per-network files are gitignored — see below.)
- `host_vars/<host>.yml` — network-independent truth about a board:

  ```yaml
  model: pi-zero-2-w           # metadata only; runtime decisions use facts
  capabilities:
    - pimoroni-enviro
    - mics6814
  ```

- `group_vars/all.yml` — the `capability_roles` map (capability → role list) and
  the default `capabilities: []`.
- `site.yml` — applies `raspberry-pi-basic` to every host, then includes the
  roles mapped from each host's declared capabilities (deterministic order;
  unknown capabilities warn and are skipped).

## Adding things

- **A sensor/HAT to an existing board:** add its capability to that board's
  `host_vars/<host>.yml`.
- **A brand-new capability type:** add a line to `capability_roles` in
  `group_vars/all.yml` too.
- **A new board:** add `host_vars/<host>.yml` + a line in each relevant
  `inventory/<network>.ini`.

## Keeping deployment info out of git

Real per-network inventories (`inventory/*.ini`) and per-host identities
(`host_vars/*`) hold your actual hostnames and IPs, so `.gitignore` keeps them
local. Only the `inventory/example.ini` and `host_vars/example-*.yml` templates
are tracked — copy them to your real names to get started.

## Architecture / OS handling

Roles read `ansible_architecture` (armv6l / armv7l / aarch64) and
`ansible_distribution_release` rather than hardcoding. For example
`raspberry-pi-extra` selects the `.deb` arch via the `deb_arch` map in its
`vars/main.yml`, and `raspberry-pi-basic` gates Docker on `ansible_memtotal_mb`
so Zero-class boards skip it automatically.

## Misc camera notes

`fswebcam` is handy for the FLIR/USB cameras; `lsusb` to confirm the device is
enumerated (Seek Thermal Compact is `289d:0010`).
