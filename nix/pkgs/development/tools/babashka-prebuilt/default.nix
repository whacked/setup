# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "babashka-prebuilt";
  version="0.2.0";

  src = fetchzip (if stdenv.isLinux then {
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
  '';

  postInstallCheck = ''
    $bin/bb --version >/dev/null
  '';

  meta = with stdenv.lib; {
    description = ''babashka by borkdude'';
    platforms = with platforms; linux;
    downloadPage = "https://github.com/borkdude/babashka";
    inherit version;
  };
}

