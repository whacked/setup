# ~/.nixpkgs/config.nix
with import <nixpkgs> {};
{
  includeDefaultPackages = (import ./util.nix)
                        ++ (import ./dev.nix)
                        ++ (import ./cloud.nix)
                        ++ (import ./gui.nix)
                        ++ (import ./dev-heavy.nix)
                        ++ (import ./electron.nix)
                        ++ (import ./desktop.nix)
                        ++ (import ./work.nix)
                        ++ (import ./containerization.nix)
                        ++ [
                          (callPackage (import ./pkgs/shells/zsh-histdb/default.nix) {})
                          (callPackage (import ./pkgs/development/tools/babashka-prebuilt/default.nix) {})
                        ];
  includeUnfreePackages = (import ./unfree.nix)
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
