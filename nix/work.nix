# other
with import <nixpkgs> {};
[
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
    sqliteman
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
