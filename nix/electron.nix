{ pkgs, ... }:
let
  pinned = builtins.fetchTarball {
    name = "nixpkgs-electron-3.0.5";
    # Commit hash
    url = https://github.com/nixos/nixpkgs/archive/82cdbb516a92335ea88de35f7ecc86285a49b135.tar.gz;
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    # nix-prefetch-url --unpack $(cat electron.nix|grep 'url = '|tr -d ';'|awk '{print $NF}')
    sha256 = "0rziswwjspj6w6b2v61xbhl8l1csi33djc78jx0fwc15saj55hhz";
  };
  pinnedPkgs = import pinned {};
in
  [ pinnedPkgs.electron ]
