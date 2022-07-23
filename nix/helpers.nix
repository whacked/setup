# debug: watchexec -w . -- "nix eval -f helpers.nix ''"

let
  pkgs = import <nixpkgs> {};
  getEnvSet = envOrPath: (
    if (builtins.typeOf envOrPath) == "set" then envOrPath else (
      import envOrPath
    )
  );
  composeEnvs = envs: (
    /*
        merge envs in REVERSE ORDER, so you call this function using
        composeEnvs [
            extraEnv1
            extraEnv2
            extraEnv3
            ...
            (pkgs.mkShell ...)
        ]
    */
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
          typeType = builtins.typeOf {};
          buildInputs = [
          ] ++ (lhsEnv.buildInputs or []) ++ (rhsEnv.buildInputs or []);
          nativeBuildInputs = [
            ~/setup/bash/nix_shortcuts.sh  # provides echo-shortcuts
          ] ++ (lhsEnv.nativeBuildInputs or []) ++ (rhsEnv.nativeBuildInputs or []);
          shellHook = (lhsEnv.shellHook or "") + ''
          '' + (rhsEnv.shellHook or "") + (
            if (builtins.typeOf lhsArg) == "path" then ''
              echo-shortcuts ${lhsArg}
            '' else ""
          );
        }
    )
  );
in {
  composeEnvs = composeEnvs;
  mkShell = deps: env: pkgs.mkShell (
    composeEnvs (deps ++ [
      env
    ])
  );
}
