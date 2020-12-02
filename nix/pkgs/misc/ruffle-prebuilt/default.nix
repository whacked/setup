# nix-shell -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'
# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "ruffle-prebuilt";
  version="nightly-2020-12-02";
  snakeCaseVersion = builtins.replaceStrings ["-"] ["_"] version;

  src = builtins.fetchurl (if pkgs.stdenv.isLinux then {
    url="https://github.com/ruffle-rs/ruffle/releases/download/${version}/ruffle_${snakeCaseVersion}_linux.tar.gz";
    sha256="12jj91nm4979v2faglf8lwmsiaz83gr2s6ijhg44n7yxf0xr7a2a";
  } else if pkgs.stdenv.isDarwin then {
    url="https://github.com/ruffle-rs/ruffle/releases/download/${version}/ruffle_${snakeCaseVersion}_mac.tar.gz";
    sha256="1aljzyzkrz4268in0p93xzf3nn5y2hmybjx1z6av69k63aivwvxl";
  } else {
    # fail
  });

  dontUnpack = true;
  installPhase = ''
    tar xvf ${src}
    mkdir -p $out/bin
    mv ruffle $out/bin/
  '';

  meta = with pkgs.lib; {
    description = ''Adobe Flash Player emulator written in Rust'';
    platforms = with platforms; linux;
    downloadPage = "https://github.com/ruffle-rs/ruffle";
    inherit version;
  };
}

