# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  version = "0.9.3";

  platforms = {
    "x86_64-linux" = {
      asset = "tuitab-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-9+M7bf34SLOT/SCn6/750JT5FR392+qynHCrnZJ+/L8=";
    };
    "aarch64-linux" = {
      asset = "tuitab-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-UW7R0LJw2O+IC7sD92BrEXvMPy5guNobUFxw1GEhUMY=";
    };
    "x86_64-darwin" = {
      asset = "tuitab-v${version}-x86_64-apple-darwin.tar.gz";
      hash = "sha256-i4X3GTbLj5cXPpJ+Sl8Wa6J1ehGHHknjPk8LZYfu0pU=";
    };
    "aarch64-darwin" = {
      asset = "tuitab-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-LstKaWFEYl5f0TEVACU+Gs1bNJpazEAQKrQ43jN+pas=";
    };
  };

  selectedPlatform = platforms.${system} or (throw "tuitab: unsupported system ${system}");
in
pkgs.stdenv.mkDerivation {
  pname = "tuitab";
  inherit version;

  src = pkgs.fetchurl {
    url = "https://github.com/denisotree/tuitab/releases/download/v${version}/${selectedPlatform.asset}";
    hash = selectedPlatform.hash;
  };

  # tarball unpacks into a versioned subdirectory; Nix auto-detects it as sourceRoot
  dontBuild = true;

  nativeBuildInputs = pkgs.lib.optional pkgs.stdenv.isLinux pkgs.autoPatchelfHook;

  installPhase = ''
    mkdir -p $out/bin
    cp tuitab $out/bin/
    chmod +x $out/bin/tuitab
  '';

  meta = with pkgs.lib; {
    description = "Terminal UI tab manager";
    homepage = "https://github.com/denisotree/tuitab";
    platforms = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
    inherit version;
  };
}
