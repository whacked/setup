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
    evince
    remmina
    pdfmod
    scrot
    pinta
    inkscape
    gimp
    git-cola
    keepassx2
    vlc
    qjackctl
    supercollider
    terminator
    xournal
    wireshark
    thunderbird
    firefox
    calibre
    zotero
    # this has a surprisingly large dependency tree
    # tortoisehg
]
