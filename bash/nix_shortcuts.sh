DEBUG_LEVEL=${DEBUG_LEVEL-0}
if [ "$DEBUG_LEVEL" -gt 0 ]; then
    echo "[level:$DEBUG_LEVEL] SOURCING $BASH_SOURCE FROM $@..."
fi

function echo-shortcuts() {
    target_file=$(realpath ${1-default.nix})
    echo "=== shortcuts from $target_file ==="
    cat $target_file | grep --color '\<\(function\|alias\)\> .\+'
}

function ensure-usercache() {
    USERCACHE=${USERCACHE-/tmp/cache}
    if [ -e $USERCACHE ]; then
        echo " - using USERCACHE from $USERCACHE"
    else
        mkdir -p $USERCACHE
    fi
}

function ensure-venv() {
    _initializer=$1
    export VIRTUAL_ENV=''${VIRTUAL_ENV-$USERCACHE/$name-venv}
    if [ -e $VIRTUAL_ENV ]; then
        echo " - using existing virtualenv in $VIRTUAL_ENV..."
        _new_venv=false
    else
        echo " - setting up virtualenv in $VIRTUAL_ENV using $(which python3)..."
        python3 -m venv $VIRTUAL_ENV
        _new_venv=true
    fi
    source $VIRTUAL_ENV/bin/activate

    if $_new_venv && [ "x$_initializer" != "x" ]; then
        echo " - running initializer: $_initializer..."
        $_initializer
    fi
}

function activate-direnv() {
    echo  - activating direnv...
    eval "$(direnv hook $(ps -p $$ -ocomm=))"
}

function create-default-nix-skeleton() {
    if [ -e default.nix ]; then
        echo "ERROR: default.nix already exists; doing nothing"
        return
    fi
    if [ $# -eq 1 ]; then
        _name=$1
    else
        _name_default=$(basename $(pwd))
        echo -n "name [$_name_default]: "
        read _name
        if [ -z "${_name}" ]; then
            _name=$_name_default
        fi
    fi
    cat > default.nix<<EOF
with import <nixpkgs> {};

let
in stdenv.mkDerivation rec {
  name = "$_name";
  env = buildEnv {
    name = name;
    paths = buildInputs;
  };
  buildInputs = [
  ];
  nativeBuildInputs = [
  ];
  shellHook = ''
  '';
}
EOF
}
