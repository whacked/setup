{ pkgs ? import <nixpkgs> }:

let
  myDir = builtins.dirOf (builtins.dirOf __curPos.file);
  getEnvSet = envOrPath: (
    if (builtins.typeOf envOrPath) == "set" then
      envOrPath
    else if (builtins.typeOf envOrPath) == "path" then (
      import envOrPath
    ) else {}
  );

  nixShortcutsPath = builtins.toPath (myDir + "/bash/nix_shortcuts.sh");
  nixShortcuts = import nixShortcutsPath { inherit pkgs; };
  jsonnetShortcutsPath = builtins.toPath (myDir + "/bash/jsonnet_shortcuts.sh");
  jsonnetShortcuts = import jsonnetShortcutsPath { inherit pkgs; };
  packageJsonnetCompositionShortcutsPath = builtins.toPath (myDir + "/bash/package-jsonnet-composition.nix.sh");
  packageJsonnetCompositionShortcuts = import packageJsonnetCompositionShortcutsPath { inherit pkgs; };

  ## pkgs = import ((import <nixpkgs> {}).fetchFromGitHub {
  ##   owner  = "nixos";
  ##   repo   = "nixpkgs";
  ##   rev    = "23.05-pre";
  ##   sha256 = "sha256-h0RTwZg+cGlV3RlH9jXBHdyA9xQfbxo2oCn1zFieE2A=";
  ## }) {};

  # pkgs = import <nixpkgs> {};
  composeEnvs = envs: (
    if (builtins.length envs) == 0 then
      {}
    else if (builtins.length envs) == 1 then
      getEnvSet (pkgs.lib.last envs)
    else (
      let
        lhsArg = pkgs.lib.head envs;
        lhsEnv = getEnvSet lhsArg;
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
        # manually skip auto echo-shortcuts; use read-shortcuts to save paths
        nixShortcuts
        (jsonnetShortcuts // {
          shellHook = jsonnetShortcuts.shellHook + ''

            read-shortcuts ${jsonnetShortcutsPath}
          '';
        })
        (packageJsonnetCompositionShortcuts // {
          shellHook = packageJsonnetCompositionShortcuts.shellHook + ''

            read-shortcuts ${packageJsonnetCompositionShortcutsPath}
          '';
        })
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
