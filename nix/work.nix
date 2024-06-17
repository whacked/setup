# other
{ pkgs, ... }:

with pkgs; [
    aspell
    cifs-utils
    texinfo
    texlive.combined.scheme-basic

    # desktop
    anki
    audacity
    calibre
    chromium
    firefox
    gimp
    git-cola
    gnome3.eog
    inkscape
    keepassxc
    pdfarranger
    pinta
    qjackctl
    remmina
    sc-im
    scrot
    # sqliteman  # removed in https://github.com/NixOS/nixpkgs/pull/174634 :-(((
    sqlitebrowser  # sqliteman conceptual successor, 3x slower :-(((
    supercollider
    terminator
    thunderbird
    visidata
    wireshark
    xournal
    zotero
    # this has a surprisingly large dependency tree
    # tortoisehg
]
