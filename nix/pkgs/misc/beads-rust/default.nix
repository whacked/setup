# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  version = "0.2.10";

  platforms = {
    "x86_64-linux" = {
      asset = "br-${version}-linux_x86_64.tar.gz";
      hash = "sha256-9jiK+Q3ljRqYr3INsGEjcUfZZO/4+lL9yKUEQfhR9zA=";
    };
    "aarch64-linux" = {
      asset = "br-${version}-linux_aarch64.tar.gz";
      hash = "sha256-Ee0TzQpe1QBC3l49lG26mETJf8yGKoIM/ZoSBGS72Z0=";
    };
    "x86_64-darwin" = {
      asset = "br-${version}-darwin_x86_64.tar.gz";
      hash = "sha256-x2us+YlWQWYgOF50ql4tEA/6PWalCw6uZfiVyQJzOhE=";
    };
    "aarch64-darwin" = {
      asset = "br-${version}-darwin_aarch64.tar.gz";
      hash = "sha256-AP+DPQyx7w9lHHWm3goIvtlwvE5+8QdSMKn8utrdo3I=";
    };
  };

  selectedPlatform = platforms.${system} or (throw "beads-rust: unsupported system ${system}");
in
pkgs.stdenv.mkDerivation rec {
  pname = "beads-rust";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/Dicklesworthstone/beads_rust/releases/download/v${version}/${selectedPlatform.asset}";
    hash = selectedPlatform.hash;
  };

  # tarball contains a single binary at the root with no subdirectory
  dontUnpack = true;

  nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;

  installPhase = ''
    tar xf ${src}
    mkdir -p $out/bin
    cp br $out/bin/
    chmod +x $out/bin/br
  '';

  meta = with pkgs.lib; {
    description = "Terminal bead-based data visualization tool";
    homepage = "https://github.com/Dicklesworthstone/beads_rust";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    inherit version;
  };
}
