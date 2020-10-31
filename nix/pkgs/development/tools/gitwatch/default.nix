# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchzip, inotify-tools, makeWrapper }:

stdenv.mkDerivation rec {
  pname = "gitwatch";
  version="0.0.1";

  src = fetchzip {
    url="https://github.com/gitwatch/gitwatch/archive/master.zip";
    sha256="0f3chr23sa7nz25wzka5d4zxnsfddf2s1psi0df9rm9xrq0b2qx0";
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

