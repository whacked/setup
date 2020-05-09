# for nix-shell
# with import <nixpkgs> {};

{ stdenv, fetchurl }:

stdenv.mkDerivation rec {
  pname = "stackup";
  version="0.5.3";

  src = fetchurl (if stdenv.isLinux then {
    url="https://github.com/pressly/sup/releases/download/v${version}/sup-linux64";
    sha256="1fdgcls4g6h264zn8qbny9c18q96bzzf28748dv94574v06h54df";
  } else if stdenv.isDarwin then {
    url="https://github.com/pressly/sup/releases/download/v${version}/sup-darwin64";
    sha256="1lgx5ay29v4pha9l2frnr63a31dvmpiafyqi96bli0slkrsq88yi";
  } else {
    # fail
  });

  dontUnpack = true;
  installPhase = ''
    mkdir -p $out/bin
    chmod +x ${src}
    mv ${src} $out/bin/sup
  '';

  postInstallCheck = ''
    $bin/sup --version >/dev/null
  '';

  meta = with stdenv.lib; {
    description = ''stackup / sup'';
    platforms = with platforms; linux ++ darwin;
    downloadPage = "https://github.com/pressly/sup";
    inherit version;
  };
}

