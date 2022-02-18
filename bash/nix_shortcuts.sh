/*/bin/true --BEGIN-polyglot-hack-- 2>/dev/null
# TODO: rename this to .nix.sh?

# COMMENTARY:
# 
# this file needs to be `import`-ed into another nix expression to be added to
# a nix shell environment.  it exposes these properties:
# .shellHook    # the bash-compatible logic
# .buildInputs  # the dependencies for the shellHook
# 
# but since this file is almost entirely bash, we use a polyglot-hack to make
# this file nix- and bash- compatible.  You can thus `source $this_file` to
# include the functions in any bash environment -- provided that you have all
# the declared dependencies
# 
# TO USE:
#   let nixShortcutsPath = path/to/nix_shortcuts.sh;
#   let nixShortcuts = (import nixShortcutsPath);
# THEN:
# buildInputs = [ ... ] ++ nixShortcuts.buildInputs;
# nativeBuildInputs = [ ... nixShortcutsPath ... ];
# OR:
# shellHook = nixShortcuts.shellHook + ...
# 
# */ rec { buildInputs = (with import <nixpkgs>{}; [ unixtools.column ]); shellHook = ". ${__curPos.file}"; ignore = ''

DEBUG_LEVEL=''${DEBUG_LEVEL-0}
if [ "$DEBUG_LEVEL" -gt 0 ]; then
    echo "[level:$DEBUG_LEVEL] SOURCING $BASH_SOURCE FROM $@..."
fi

_SHORTCUTS_HELP=''${_SHORTCUTS_HELP-}
function echo-shortcuts() {  # usually: echo-shortcuts ''${__curPos.file}
    input_file=$1
    if [ "x$input_file" == "" ]; then
        for candidate in shell.nix default.nix; do
            if [ -e $candidate ]; then
                input_file=$candidate
                break
            fi
        done
    fi
    target_file=$(realpath "$input_file")
    target_relpath=$(realpath --relative-to="$PWD" $target_file)
    # assume the shorter path is easier to read
    if [ ''${#target_relpath} -lt ''${#target_file} ]; then
        show_path=$target_relpath
    else
        show_path=$target_file
    fi
    help_string=
    help_string="$help_string=== shortcuts from $show_path ===\n"
    help_string="$help_string"'\033[0;33m'$(
        cat $target_file |
        grep --color '^\s*\([a-z][-a-zA-Z0-9]*()\|function [a-zA-Z]\).\+' |
        sed 's/^\s*/  /' |
        sed 's/#\s*\(.*\)$/\t\\033\[0;37m\1\\033[0;33m/' |  # replace comment string with <tab> delimiter; set to white, then back to yellow
        column -t -s $'\t'  # print in columns using <tab> as delimiter
    )'\033[0m'
    help_string="$help_string"'\n\033[0;35m'$(
        cat $target_file |
        grep --color '^\s*\(alias\).\+' |
        sed 's/^\s*/  /'
    )'\033[0m'
    _SHORTCUTS_HELP="''${_SHORTCUTS_HELP}$help_string\n"
    echo -e "$help_string"
}

function shortcuts() {
    echo -e "$_SHORTCUTS_HELP"
}

function ensure-usercache() {
    USERCACHE=''${USERCACHE-/tmp/cache}
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
        if [ -z "''${_name}" ]; then
            _name=$_name_default
        fi
    fi
    II="'""'"
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
    direnv
    lorri
  ];  # join lists with ++
  nativeBuildInputs = [
    ~/setup/bash/nix_shortcuts.sh
  ];
  shellHook = $II
    eval "\$(direnv hook bash)"
    if [ ! -e .envrc ]; then
        lorri init
    fi
  $II;  # join strings with +
}
EOF
}

function create-nix-shell-skeleton() {
    # https://nixos.wiki/wiki/Development_environment_with_nix-shell
    if [ -e shell.nix ]; then
        echo "ERROR: shell.nix already exists; doing nothing"
        return
    fi
    II="'""'"
    cat > shell.nix<<EOF
{ pkgs ? import <nixpkgs> {} }:
pkgs.mkShell {
  buildInputs = [
  ];  # join lists with ++

  nativeBuildInputs = [
    ~/setup/bash/nix_shortcuts.sh
  ];

  shellHook = $II
    echo-shortcuts \${__curPos.file}
  $II;  # join strings with +
}
EOF
}

#  PS1 for nix-shell bash when liquidprompt is available
if [[ -n "$IN_NIX_SHELL" ]]; then
    LP_HOSTNAME_ALWAYS=1
    LP_ENABLE_TIME=1
    if [ "''${name}" == "nix-shell" ]; then
        LP_MARK_PREFIX="\n\[\033[1;32m\][nix-shell]\[\033[0m\]"
        :
    else
        LP_MARK_PREFIX="\n\[\033[1;32m\][nsh:''${name}]\[\033[0m\]"
        :
    fi
fi

# --END-polyglot-hack-- ''; }
