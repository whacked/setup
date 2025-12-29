{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin"; # Or "x86_64-linux" for Linux
      pkgs = nixpkgs.legacyPackages.${system};
      # Import your existing default.nix
      ck = pkgs.callPackage ./default.nix { };
    in
    {
      # This allows 'nix shell' and 'nix run' to work
      packages.${system}.default = ck;

      # This allows 'nix develop' to put 'ck' in the PATH
      devShells.${system}.default = pkgs.mkShell {
        packages = [ ck ];
      };
    };
}
