# nix-build -E 'with import <nixpkgs> { }; callPackage ./default.nix { }'

{ pkgs ? import <nixpkgs> {} }:

pkgs.rustPlatform.buildRustPackage rec {
  pname = "tv";
  version = "1.8.93";

  src = pkgs.fetchFromGitHub {
    owner = "alexhallam";
    repo  = "tv";
    rev   = version;
    hash  = "sha256-wiVcdTnjEFh5kSyxmK+ab0LkEAbQaygmLdrFfM12DyM=";
  };

  cargoHash = "sha256-HF7M4s2OHCAyVkbCIBxGButAxbxrhjmY3YE/do8et1s=";

  meta = with pkgs.lib; {
    description = "Terminal CSV viewer (tidy-viewer)";
    homepage    = "https://github.com/alexhallam/tv";
    license     = licenses.mit;
    mainProgram = "tv";
  };
}
