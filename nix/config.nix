# ~/.nixpkgs/config.nix
{ pkgs, inputs, ... }:

let
  lib        = pkgs.lib;
  userConfig = import /etc/nix/user-config.nix;

  tagMap = {
    dev              = (import ./dev.nix)              { inherit pkgs; };
    cloud            = (import ./cloud.nix)            { inherit pkgs; };
    gui              = (import ./gui.nix)              { inherit pkgs; };
    desktop          = (import ./desktop.nix)          { inherit pkgs; };
    work             = (import ./work.nix)             { inherit pkgs; };
    dev-heavy        = (import ./dev-heavy.nix)        { inherit pkgs; };
    electron         = (import ./electron.nix)         { inherit pkgs; };
    containerization = (import ./containerization.nix) { inherit pkgs; };
    unfree           = (import ./unfree.nix)           { inherit pkgs; };
    misc-utils       = [
      (pkgs.callPackage (import ./pkgs/development/tools/bootleg-prebuilt/default.nix) {})
      (pkgs.callPackage (import ./pkgs/development/tools/jet/default.nix) {})
      (pkgs.callPackage (import ./pkgs/development/tools/ck/default.nix) {})
      (pkgs.callPackage (import ./pkgs/misc/ruffle-prebuilt/default.nix) {})
    ];
  };

  unknownTags = builtins.filter (tag: !(tagMap ? ${tag})) (userConfig.tags or []);
  taggedPkgs  = if unknownTags != []
    then builtins.throw "Unknown tags in user-config: ${lib.concatStringsSep ", " unknownTags}"
    else lib.concatMap (tag: tagMap.${tag}) (userConfig.tags or []);

in {
  includeDefaultPackages = (import ./util.nix) { inherit pkgs inputs; }
  ++ taggedPkgs;
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
