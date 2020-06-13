# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchgit }:

stdenv.mkDerivation rec {
  pname = "zsh-histdb";
  version="2";

  src = fetchgit {
    url="https://github.com/larkery/zsh-histdb";
    rev="refs/heads/master";
    sha256="04i8gsixjkqqq0nxmd45wp6irbfp9hy71qqxkq7f6b78aaknljwf";
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

