# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

let
  inherit (pkgs.stdenv.hostPlatform) system;
  version = "0.4.2";

  platforms = {
    "x86_64-linux" = {
      asset = "tuitab-v${version}-x86_64-unknown-linux-gnu.tar.gz";
      hash = "sha256-KIkxHv2OEH1ug3huF/iLdGce7F20EXPtzkO+jYxF8Vg=";
    };
    "aarch64-linux" = {
      asset = "tuitab-v${version}-aarch64-unknown-linux-gnu.tar.gz";
      hash = "sha256-PuQeKWOc+uPYx40XaHd1yv9y4ia1fdInp9ecV0LHopw=";
    };
    "x86_64-darwin" = {
      asset = "tuitab-v${version}-x86_64-apple-darwin.tar.gz";
      hash = "sha256-6ZnjyNR7sqLuXWdHqkOC8P2nVOLLpqqFn8ZDnwSnHLE=";
    };
    "aarch64-darwin" = {
      asset = "tuitab-v${version}-aarch64-apple-darwin.tar.gz";
      hash = "sha256-eTBhPFskidEvrB1beTVDzqMFem6r8iV5rvA2dEFMPJ0=";
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
