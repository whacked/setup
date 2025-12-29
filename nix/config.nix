# ~/.nixpkgs/config.nix
{ pkgs, inputs, ... }:

let
in {
  includeDefaultPackages = (import ./util.nix) { inherit pkgs inputs; }
  ++ (if pkgs.stdenv.isLinux then (
    []
    ++ (import ./dev.nix) { inherit pkgs; }
    ++ (import ./cloud.nix) { inherit pkgs; }
    ++ (import ./gui.nix) { inherit pkgs; }
    ++ (import ./dev-heavy.nix) { inherit pkgs; }
    ++ (import ./electron.nix) { inherit pkgs; }
    ++ (import ./desktop.nix) { inherit pkgs; }
    ++ (import ./work.nix) { inherit pkgs; }
    ++ (import ./containerization.nix) { inherit pkgs; }
    ++ [
      (pkgs.callPackage (import ./pkgs/shells/zsh-histdb/default.nix) {})
      (pkgs.callPackage (import ./pkgs/development/tools/bootleg-prebuilt/default.nix) {})
      (pkgs.callPackage (import ./pkgs/development/tools/jet/default.nix) {})
      (pkgs.callPackage (import ./pkgs/misc/ruffle-prebuilt/default.nix) {})
    ])
    else
    [
    ])
  ++ [
    (pkgs.callPackage (import ./pkgs/development/tools/ck/default.nix) {})
  ];
  includeUnfreePackages = (import ./unfree.nix) { inherit pkgs; }
                          ;
  packageOverrides = defaultPkgs: with defaultPkgs; {
    # To install below "pseudo-package", run:
    #  $ nix-env -i all
    # or:
    #  $ nix-env -iA nixos.all

    # required to build packages in unfree.nix
    allowUnfree = true;

    # fixes installation failure due to package binary symlink
    # conflicts; in particular:
    # - mercurial <> tortoisehg
    # however, it causes an extremely large compilation overhead.
    # you should check whether the conflicts have been resolved
    # and/or new conflicts have arisen
    # ignoreCollisions = true;

    # using this method seems to cause conflicts at every package that
    # was installed separately via nix-env -i $package; in doing so
    # you need to uninstall ecach of those indpependently installed
    # packages, to get this pseudo-package to work
    all = with pkgs; buildEnv {
      name = "my-custom-nixpkgs";
      paths = includeDefaultPackages ++ includeUnfreePackages;
    };
  };
}
