# for nix-shell
# with import <nixpkgs> {};
{ pkgs ? import <nixpkgs> {} }:

# { stdenv, fetchzip }:

pkgs.stdenv.mkDerivation rec {
  pname = "babashka-prebuilt";
  version="0.2.0";

  src = pkgs.fetchzip (if pkgs.stdenv.isLinux then {
    url="https://github.com/borkdude/babashka/releases/download/v${version}/babashka-${version}-linux-static-amd64.zip";
    sha256="035rbwjxphw0k1ay94v91zk6xndq0rff9sq54jn2fmhvww2ws6qn";
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

