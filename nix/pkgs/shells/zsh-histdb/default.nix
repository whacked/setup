# for nix-shell
# with import <nixpkgs> {};

{ lib, stdenv, fetchgit }:

stdenv.mkDerivation rec {
  pname = "zsh-histdb";
  version="2";

  src = fetchgit {
    url="https://github.com/larkery/zsh-histdb";
    rev="refs/heads/master";
    sha256="1f7xz4ykbdhmjwzcc3yakxwjb0bkn2zlm8lmk6mbdy9kr4bha0ix";
  };

  installPhase = ''
    ln -s $src $out
  '';

  meta = with lib; {
    description = ''zsh-histdb'';
    downloadPage = "https://github.com/larkery/zsh-histdb";
    inherit version;
  };
}

