# for nix-shell
# with import <nixpkgs> {};

{ lib, stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "exo";
  version="2021.11.16";

  src = fetchzip (if stdenv.isLinux then {
    url="https://github.com/deref/exo/releases/download/${version}/exo_standalone_${version}_linux_amd64.tar.gz";
    sha256="1ic8gri43x2jfnsjcg8miwsg1xn0mjnbkd1ixprcshf7xkiym06a";
    stripRoot=false;
  } else if stdenv.isDarwin then {
    url="https://github.com/deref/exo/releases/download/${version}/exo_standalone_${version}_darwin_arm64.tar.gz";
    sha256="0000000000000000000000000000000000000000000000000000";
    stripRoot=false;
  } else {
    # fail
  });

  installPhase = ''
    mkdir -p $out/bin
    find .
    ls -lrt
    cp ${src}/exo $out/bin/
  '';

  postInstallCheck = ''
    $bin/exo version >/dev/null
  '';

  meta = with lib; {
    description = ''process manager & log viewer'';
    platforms = with platforms; linux ++ darwin;
    downloadPage = "https://github.com/deref/exo";
    inherit version;
  };
}

