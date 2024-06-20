# for nix-shell
# with import <nixpkgs> {};

{ lib, stdenv, fetchgit }:

stdenv.mkDerivation rec {
  pname = "zsh-histdb";
  version="2";

  src = fetchgit {
    url="https://github.com/larkery/zsh-histdb";
    rev="refs/heads/master";
    hash="sha256-vtG1poaRVbfb/wKPChk1WpPgDq+7udLqLfYfLqap4Vg=";
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

