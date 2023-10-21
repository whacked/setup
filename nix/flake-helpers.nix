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

  nixShortcutsPath = builtins.toPath (myDir + "/bash/nix_shortcuts.nix.sh");
  nixShortcuts = import nixShortcutsPath { inherit pkgs; };
  jsonnetShortcutsPath = builtins.toPath (myDir + "/bash/jsonnet_shortcuts.nix.sh");
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
  loadFlakeDerivation = flakeExpressionFile: flakeOutputRequires: (
    # MINIMUM REQUIREMENTS:
    # (loadFlakeDerivation ./path/to/flake.nix { inherit pkgs; })
    # (loadFlakeDerivation ./path/to/flake.nix { pkgs = other-pkgs; })
    let
      # HACK! but due to https://github.com/NixOS/nix/issues/3966
      # it is not straightforward to extract attributes from the imported flake;
      # can't use flake-utils.url because the library arg needs `lib`
      flake-utils-repo = import (flakeOutputRequires.pkgs.fetchFromGitHub {
        owner = "numtide";
        repo = "flake-utils";
        rev = "919d646de7be200f3bf08cb76ae1f09402b6f9b4";  # 2023-07-11
        hash = "sha256-6ixXo3wt24N/melDWjq70UuHQLxGV8jZvooRanIHXw0=";
      });
      system = flakeOutputRequires.pkgs.system;
      mergedOutputRequires = (builtins.removeAttrs flakeOutputRequires ["pkgs"]) // {
        self = null;
        nixpkgs = {
          legacyPackages = {
            ${pkgs.system} = flakeOutputRequires.pkgs;
          };
        };
        flake-utils = {
          lib = flake-utils-repo;
        };
        whacked-setup = ./..;
      };
    in
      ((import flakeExpressionFile).outputs mergedOutputRequires).devShell.${system}
  );
}
