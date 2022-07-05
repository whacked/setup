# nix-shell -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'
# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "bkt-prebuilt";
  version="0.5.4";

  src = pkgs.fetchzip (if pkgs.stdenv.isLinux then {
    url="https://github.com/dimo414/bkt/releases/download/${version}/bkt.v${version}.x86_64-unknown-linux-gnu.zip";
    sha256="00r2gbpm4vpf0gqg83xflkm7krz76phz6mmmmscs17g2hazz8ypd";
  } else {
    # fail
  });

  installPhase = ''
    mkdir -p $out/bin
    cp $src/bkt $out/bin/
    chmod +x $out/bin/bkt
  '';

  meta = with pkgs.lib; {
    description = ''bkt'';
    platforms = with platforms; linux;
    downloadPage = "https://github.com/dimo414/bkt";
    inherit version;
  };
}
