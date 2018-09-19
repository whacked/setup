# desktop
with import <nixpkgs> {};
[
    eog
    evince
    firefox
    git-cola
    terminator
    (import ./electron.nix)
]
