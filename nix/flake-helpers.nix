let
  myDir = builtins.dirOf (builtins.dirOf __curPos.file);

  jsonnetShortcutsPath = builtins.toPath (myDir + "/bash/jsonnet_shortcuts.sh");
  packageJsonnetCompositionShortcutsPath = builtins.toPath (myDir + "/bash/package-jsonnet-composition.nix.sh");
  nixShortcuts = import (builtins.toPath (myDir + "/bash/nix_shortcuts.sh"));

  # pkgs = import ((import <nixpkgs> {}).fetchFromGitHub {
  #   # this provides kubectl 1.11; 1.26 is latest as of this commit, and it doesn't work:
  #   # error: exec plugin: invalid apiVersion "client.authentication.k8s.io/v1alpha1"
  #   owner  = "nixos";
  #   repo   = "nixpkgs";
  #   rev    = "23.05-pre";
  #   sha256 = "sha256-h0RTwZg+cGlV3RlH9jXBHdyA9xQfbxo2oCn1zFieE2A=";
  # }) {};

  pkgs = import <nixpkgs> {};
  helpers = import ./helpers.nix;
  composeEnvs = envs: (
    if (builtins.length envs) == 0 then
      {}
    else if (builtins.length envs) == 1 then
      helpers.getEnvSet (pkgs.lib.last envs)
    else (
      let
        lhsArg = pkgs.lib.head envs;
        lhsEnv = helpers.getEnvSet lhsArg;
        rhsEnv = composeEnvs (pkgs.lib.tail envs);
      in
        rhsEnv // {
          buildInputs = []
          ++ (lhsEnv.buildInputs or []) ++ (rhsEnv.buildInputs or []);
          nativeBuildInputs = []
          ++ (
            # ref https://discourse.nixos.org/t/debug-a-nix-expression-with-debug-trace-statements/691
            lhsEnv.nativeBuildInputs or []
          ) ++ (
            rhsEnv.nativeBuildInputs or []
          );
          shellHook = "
          " + (builtins.toString (lhsEnv.shellHook or "")) + (
            if ((builtins.typeOf lhsArg) == "path" || (builtins.typeOf lhsArg) == "string") then ''
              . ${lhsArg}
              echo-shortcuts ${lhsArg}
            '' else ""
          ) + "
          " + (builtins.toString (rhsEnv.shellHook or "")
          );
        }
    )
  );
in {
  # config:
  # {
  #   flakeFile = __curPos.file;  # should ALWAYS be this, just so we can call echo-shorcuts
  #   includeScripts: [...];      # paths to any shell scripts to load
  # }
  mkShell = config: env: (
    # to debug:
    # (builtins.trace (builtins.typeOf deps)) (builtins.trace env) 
    pkgs.mkShell (composeEnvs (
      [
        # manually stuff nixShortcuts to skip auto echo-shortcuts
        {
          buildInputs = nixShortcuts.buildInputs;
          shellHook = nixShortcuts.shellHook;
        }
        jsonnetShortcutsPath
        packageJsonnetCompositionShortcutsPath
      ] ++ config.includeScripts ++ [
        env 
        {
          shellHook = ''
            echo-shortcuts ${config.flakeFile}
            echo
          '';
        }
      ]
    ))
  );
}
