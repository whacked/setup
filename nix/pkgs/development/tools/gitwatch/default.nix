# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchzip }:

stdenv.mkDerivation rec {
  pname = "gitwatch";
  version="0.0.1";

  src = fetchzip {
    url="https://github.com/gitwatch/gitwatch/archive/master.zip";
    sha256="17hbg0qrhh2l060c03d4a1f7s5afwjp3w57hy8lgpzbz72hyj4ca";
  };

  installPhase = ''
    find .
    mkdir -p $out/bin
    chmod +x gitwatch.sh
    mv gitwatch.sh $out/bin/
  '';

  postInstallCheck = ''
  '';

  meta = with stdenv.lib; {
    description = ''gitwatch'';
    downloadPage = "https://github.com/gitwatch/gitwatch";
    inherit version;
  };
}

