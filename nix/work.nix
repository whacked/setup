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
    sqliteman
    chromium
    gnome3.eog
    remmina
    pdfarranger
    scrot
    pinta
    inkscape
    gimp
    git-cola
    keepassxc
    qjackctl
    supercollider
    terminator
    xournal
    wireshark
    thunderbird
    firefox
    calibre
    visidata
    zotero
    # this has a surprisingly large dependency tree
    # tortoisehg
]
