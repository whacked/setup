# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchgit }:

stdenv.mkDerivation rec {
  pname = "zsh-histdb";
  version="2";

  src = fetchgit {
    url="https://github.com/larkery/zsh-histdb";
    rev="refs/heads/master";
    sha256="1zh3r090jh6n6xwb4d2qvrhdhw35pc48j74hvkwsq06g62382zk3";
  };

  installPhase = ''
    ln -s $src $out
  '';

  meta = with stdenv.lib; {
    description = ''zsh-histdb'';
    downloadPage = "https://github.com/larkery/zsh-histdb";
    inherit version;
  };
}

