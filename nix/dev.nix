# dev
with import <nixpkgs> {};

let
  pinnedNixPkgs = import (fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "8c5d37129fc5097d9fb52e95fb07de75392d1c3c";
    sha256 = "02ahrhr1s7b2g0x1xqhyyk1kk7x0q5nifddnih7pckcmkkxcgiip";
  }) {};
  swftools = pinnedNixPkgs.swftools;
in
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
    lorri
    maven
    meld
    nodejs
    poppler

    python3Full
    python39Packages.ipython

    swftools
    dos2unix
    cargo
    rustc
    watchexec
    zlib
]
