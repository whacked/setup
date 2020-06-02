with import <nixpkgs> {};

let
in stdenv.mkDerivation rec {
  name = "beakerx-env";
  env = buildEnv {
    name = name;
    paths = buildInputs;
  };
  nativeBuildInputs = [
    ~/setup/bash/nix_shortcuts.sh
  ];
  buildInputs = [
    python37Full
    gcc-unwrapped
  ];

  shellHook = ''
    export LD_LIBRARY_PATH=${gcc-unwrapped.lib}/lib:$LD_LIBRARY_PATH
    function setup() {
       pip install beakerx ipywidgets pandas numpy py4j requests
       beakerx install
    }
    ensure-venv setup
  '';
}

