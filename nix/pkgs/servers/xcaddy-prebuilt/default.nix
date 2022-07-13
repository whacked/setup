# nix-shell -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'
# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "xcaddy-prebuilt";
  version="0.3.0";

  src = pkgs.fetchurl (if pkgs.stdenv.isLinux then {
    url="https://github.com/caddyserver/xcaddy/releases/download/v${version}/xcaddy_${version}_linux_amd64.tar.gz";
    sha256="034abzgqaisifzkchj3a98grcf4b1p20isbkj6nh16lgg8lmq87h";
  } else {
    # fail
  });

  dontUnpack = true;

  installPhase = ''
    tar xf $src
    mkdir -p $out/bin
    cp xcaddy $out/bin/
    chmod +x $out/bin/xcaddy
  '';

  meta = with pkgs.lib; {
    description = ''xcaddy'';
    platforms = with platforms; linux;
    downloadPage = "https://github.com/caddyserver/xcaddy";
    inherit version;
  };
}
