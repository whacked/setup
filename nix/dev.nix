# dev
with import <nixpkgs> {};
[
    R
    cairo
    cmake
    gcc
    go
    hy
    jdk11
    leiningen
    libpng
    # contains a newer version of libvterm
    # in particular, the base "libvterm" cannot build vterm for emacs
    libvterm-neovim
    maven
    meld
    nodejs
    poppler

    python3Full
    python37Packages.ipython

    swftools
    dos2unix
    cargo
    rustc
    watchexec
    zlib
]
