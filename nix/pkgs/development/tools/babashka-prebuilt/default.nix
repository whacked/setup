# for nix-shell
# with import <nixpkgs> {};
{ pkgs ? import <nixpkgs> {} }:

# { stdenv, fetchzip }:

pkgs.stdenv.mkDerivation rec {
  pname = "babashka-prebuilt";
  version="0.3.2";

  src = pkgs.fetchzip (if pkgs.stdenv.isLinux then {
    url="https://github.com/borkdude/babashka/releases/download/v${version}/babashka-${version}-linux-static-amd64.tar.gz";
    sha256="08sb5ydrzrnlrl8j83kbz28s0ilqqx7s6nkyrxd6yvgpm4w0ghza";
  } else {
    # fail
  });

  installPhase = ''
    whoami
    mkdir -p $out/bin
    pwd
    find .
    cp ${src}/bb $out/bin/
    ls
  '';

  shellHook = ''
    which bb

  '';

  postInstallCheck = ''
    $bin/bb --version >/dev/null
  '';

  meta = with pkgs.lib; {
    description = ''babashka by borkdude'';
    platforms = with platforms; linux;
    downloadPage = "https://github.com/borkdude/babashka";
    inherit version;
  };
}

