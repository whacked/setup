# ~/.nixpkgs/config.nix
{
  packageOverrides = defaultPkgs: with defaultPkgs; {
    # To install below "pseudo-package", run:
    #  $ nix-env -i all
    # or:
    #  $ nix-env -iA nixos.all

    # using this method seems to cause conflicts at every package that
    # was installed separately via nix-env -i $package; in doing so
    # you need to uninstall ecach of those indpependently installed
    # packages, to get this pseudo-package to work
    all = with pkgs; buildEnv {
      name = "all";
      paths = (import ./util.nix)
           ++ (import ./dev.nix)
         # ++ (import ./desktop.nix)  # example
           ++ [
           # other custom packages
           # tortoisehg
           # synergy-1.7.6
      ];
    };
  };
}
