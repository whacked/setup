# for nix-shell
# with import <nixpkgs> {};

{ lib, stdenv, fetchgit }:

stdenv.mkDerivation rec {
  pname = "zsh-histdb";
  version="2";

  src = fetchgit {
    url="https://github.com/larkery/zsh-histdb";
    rev="refs/heads/master";
    sha256="0isbfmqd0slz4d9q6jxy09v5b3vs2pq1yicxqig36iadpxbawcbb";
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

