# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchzip, inotify-tools, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "gitwatch";
  version="0.0.1";

  src = fetchzip {
    url="https://github.com/gitwatch/gitwatch/archive/master.zip";
    sha256="1jrjvzi3lka05dv0g4jswajak2w267995fcvka4bnkfik71k8kmv";
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

  meta = with stdenv.lib; {
    description = ''gitwatch'';
    downloadPage = "https://github.com/gitwatch/gitwatch";
    inherit version;
  };
}

