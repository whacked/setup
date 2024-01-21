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
    babashka
    delta
    dos2unix
    go
    leiningen
    libpng
    lorri
    maven
    niv
    nodejs
    python3
    python3Packages.ipython
    watchexec
    zlib
] ++ (if stdenv.isLinux then [
    cairo
    cargo
    cmake
    gcc
    hy
    jdk11
    # contains a newer version of libvterm
    # in particular, the base "libvterm" cannot build vterm for emacs
    libvterm-neovim
    meld
    poppler
    rustc
    swftools
] else if stdenv.isDarwin then [
] else [
])
