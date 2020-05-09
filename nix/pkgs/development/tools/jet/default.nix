# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "jet";
  version="0.0.12";

  src = fetchzip (if stdenv.isLinux then {
    url="https://github.com/borkdude/jet/releases/download/v${version}/jet-${version}-linux-amd64.zip";
    sha256="10jmbak00i3n2pq6qvia8ljcdsby0b2zm6g9pff54nq9x5xg9f7w";
  } else if stdenv.isDarwin then {
    url="https://github.com/borkdude/jet/releases/download/v${version}/jet-${version}-macos-amd64.zip";
    sha256="1b8vs4giw4d38xbnm3s3bxn951izhdk8mddvlsz7fc0v3n5vx4md";
  } else {
    # fail
  });

  installPhase = ''
    mkdir -p $out/bin
    cp ${src}/jet $out/bin/
  '';

  postInstallCheck = ''
    $bin/jet --version >/dev/null
  '';

  meta = with stdenv.lib; {
    description = ''borkdude/jet CLI json/edn/transit'';
    platforms = with platforms; linux ++ darwin;
    downloadPage = "https://github.com/borkdude/jet";
    inherit version;
  };
}

