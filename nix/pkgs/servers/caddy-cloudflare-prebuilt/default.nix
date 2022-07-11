# nix-shell -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'
# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

pkgs.stdenv.mkDerivation rec {
  pname = "caddy-with-cloudflare-prebuilt";
  version="2.5.1";

  src = pkgs.fetchurl (if pkgs.stdenv.isLinux then {
    url="https://caddyserver.com/api/download?os=linux&arch=amd64&p=github.com%2Fcaddy-dns%2Fcloudflare&idempotency=41827454289411";
    sha256="0mmnsjdim4navdd21nrdbjnidnz5iyzm1yppv2l2992g1s47y6jf";
    name="caddy_linux_amd64_custom";
  } else {
    # fail
  });

  dontUnpack = true;

  installPhase = ''
    mkdir -p $out/bin
    cp $src $out/bin/caddy
    chmod +x $out/bin/caddy
  '';

  meta = with pkgs.lib; {
    description = ''caddy with cloudflare'';
    platforms = with platforms; linux;
    downloadPage = "https://caddyserver.com/download";
    inherit version;
  };
}
