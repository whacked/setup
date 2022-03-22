# for nix-shell, uncomment `with`, comment out { lib ... }, and nix-shell from cwd
# with import <nixpkgs> {};
{ lib, stdenv, fetchzip, inotify-tools, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "gitwatch";
  version="0.0.1";

  src = fetchzip {
    url="https://github.com/gitwatch/gitwatch/archive/master.zip";
    sha256="1n78iffrdpmzrkbr1hbip41g9ifcwi9f9gygfifdw19q7v842bqp";
  };

  buildInputs = [
    makeWrapper
  ];

  installPhase = ''
    find .
    mkdir -p $out/bin
    chmod +x gitwatch.sh
    mv gitwatch.sh $out/bin/
    makeWrapper $out/bin/gitwatch.sh $out/bin/gitwatch \
        --prefix PATH : ${inotify-tools}/bin
  '';

  meta = with lib; {
    description = ''gitwatch'';
    downloadPage = "https://github.com/gitwatch/gitwatch";
    inherit version;
  };
}

