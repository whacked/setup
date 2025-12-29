{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  version = "0.7.0";

  # 1. Map Nix systems to the GitHub asset names and hashes you provided
  platforms = {
    "x86_64-linux" = {
      asset = "ck-${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
    };
    "aarch64-darwin" = {
      asset = "ck-${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-UTf9KWPVedojR3pEaB+C53ZG4fljmqMEEOcySdCkvmo="; 
    };
    "x86_64-darwin" = {
      asset = "ck-${version}-x86_64-apple-darwin.tar.gz";
      hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="; 
    };
  };

  # 2. Select the metadata for the current machine
  selectedPlatform = platforms.${system} or (throw "Unsupported system: ${system}");

in
pkgs.stdenv.mkDerivation {
  pname = "ck";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/BeaconBay/ck/releases/download/${version}/${selectedPlatform.asset}";
    sha256 = selectedPlatform.hash;
  };

  # FIX 1: Tell Nix not to look for a subdirectory after unpacking
  sourceRoot = ".";

  # FIX 2: Since we are using fetchurl on a .tar.gz, Nix will unpack it automatically.
  # We just need to skip the build step and define how to 'install' it.
  dontBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ck $out/bin/
    chmod +x $out/bin/ck
  '';

  # Mac binaries usually 'just work', but Linux binaries often need this:
  nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;
  buildInputs = [ pkgs.openssl pkgs.zlib pkgs.sqlite ];
}
