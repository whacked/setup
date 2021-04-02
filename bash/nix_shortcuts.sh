DEBUG_LEVEL=${DEBUG_LEVEL-0}
if [ "$DEBUG_LEVEL" -gt 0 ]; then
    echo "[level:$DEBUG_LEVEL] SOURCING $BASH_SOURCE FROM $@..."
fi

_SHORTCUTS_HELP=${_SHORTCUTS_HELP-}
function echo-shortcuts() {
    target_file=$(realpath ${1-*.nix})
    target_relpath=$(realpath --relative-to=$PWD $target_file)
    help_string=
    help_string="$help_string=== shortcuts from $target_relpath ===\n"
    help_string="$help_string"'\033[0;33m'$(cat $target_file | grep --color '^\s*\([a-z][-a-zA-Z0-9]*()\|function [a-zA-Z]\).\+')'\033[0m'
    help_string="$help_string"'\n\033[0;35m'$(cat $target_file | grep --color '^\s*\(alias\).\+')'\033[0m'
    _SHORTCUTS_HELP="${_SHORTCUTS_HELP}$help_string\n"
    echo -e "$help_string"
}

function shortcuts() {
    echo -e "$_SHORTCUTS_HELP"
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

function create-nix-shell-skeleton() {
    # https://nixos.wiki/wiki/Development_environment_with_nix-shell
    if [ -e shell.nix ]; then
        echo "ERROR: shell.nix already exists; doing nothing"
        return
    fi
    cat > shell.nix<<'EOF'
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
    pkgs.direnv
    pkgs.lorri
  ];

  shellHook = ''
    eval "$(direnv hook bash)"
    if [ ! -e .envrc ]; then
        lorri init
    fi
  '';
}
EOF
}

