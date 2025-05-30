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
#   let nixShortcutsPath = path/to/nix_shortcuts.nix.sh;
#   let nixShortcuts = (import nixShortcutsPath);
# THEN:
# buildInputs = [ ... ] ++ nixShortcuts.buildInputs;
# nativeBuildInputs = [ ... nixShortcutsPath ... ];
# OR:
# shellHook = nixShortcuts.shellHook + ...
# 
# NOTE: it's unclear what's the benefit of doing this "source <filepath>" + long "ignore" string
#       method rathern than simply using shellHook, except for a more compact shellHook string.
# */ { pkgs ? import <nixpkgs> }: /*
# */ rec { buildInputs = [ pkgs.unixtools.column ]; shellHook = ". ${__curPos.file};"; ignore = ''

DEBUG_LEVEL=''${DEBUG_LEVEL-0}
if [ "$DEBUG_LEVEL" -gt 0 ] && [ "x$@" != "x" ]; then
    echo "[level:$DEBUG_LEVEL] SOURCING $BASH_SOURCE FROM $@..."
fi

_SHORTCUTS_HELP=''${_SHORTCUTS_HELP-}
declare -A -g _SHORTCUTS_PATHS  # -g (global) makes the array available in functions

function _denixify_escape() {
    # prettification hack for bash, because nix needs to escape dollar curly
    sed -e "s|^'\+||"
}

function _print-shortcuts-header() {
    echo -e "=== shortcuts from \e[94;2m$*\e[0m ==="
}

function echo-shortcuts() {  # usually: echo-shortcuts ''${__curPos.file}
    if [ "x$SHOULD_SILENCE_SHORTCUTS" != "x" ]; then
        return
    fi
    input_file="$*"
    if [ "x$input_file" == "x" ]; then
        for candidate in shell.nix default.nix; do
            if [ -e $candidate ]; then
                input_file=$candidate
                break
            fi
        done
    fi
    target_file=$(realpath "$input_file")
    target_relpath=$(realpath --relative-to="$PWD" "$target_file")
    # assume the shorter path is easier to read
    if [ ''${#target_relpath} -lt ''${#target_file} ]; then
        show_path="$target_relpath"
    else
        show_path="$target_file"
    fi

    if [ "$(echo x''${_SHORTCUTS_PATHS[$show_path]})" != "x" ]; then
        return
    fi

    help_string=
    help_string="$help_string"'\033[0;33m'$(
        cat "$target_file" |
        grep --color '^\s*\([a-z][-a-zA-Z0-9]*()\|function [a-zA-Z]\).\+' |
        sed 's/^\s*/  /' |
        sed 's/#\s*\(.*\)$/\t\\033\[0;37m\1\\033[0;33m/' |  # replace comment string with <tab> delimiter; set to white, then back to yellow
        column -t -s $'\t'  # print in columns using <tab> as delimiter
    )'\033[0m'
    help_string="$help_string"'\n\033[0;35m'$(
        cat "$target_file" |
        grep '^\s*\(alias\).\+' |
        sed 's/^\s*alias\s*\([^=]\+\)/  \\033[0;35malias \\033[0;36m\1\\033[0m/'
    )'\033[0m'
    _SHORTCUTS_HELP=''${_SHORTCUTS_HELP}"$help_string\n"
    _SHORTCUTS_PATHS["$show_path"]="$help_string"
    echo -e "$help_string"
}

function read-shortcuts() {
    echo-shortcuts $* >/dev/null
}

function shortcuts() {
    # Set the flag based on a string comparison
    if [ "$1" == "--all" ]; then
        _should_show_all_shortcuts=true
    else
        _should_show_all_shortcuts=false
    fi

    _num_printed=0
    _num_skipped=0
    for nix_escaped_key in "''${!_SHORTCUTS_PATHS[@]}"; do
        key=$(echo $nix_escaped_key | _denixify_escape)
        _shortcut_path=$(echo "''${_SHORTCUTS_PATHS[$key]}")
        _should_print=false
        # assume files within the same entrypoint dir are "main" files
        # that are most central to the current repository's operation
        if [[ $key == $_ENTRYPOINT_ENV_DIR* ]]; then
            _should_print=true
        elif $_should_show_all_shortcuts; then
            _should_print=true
        fi
        
        if $_should_print; then
            _print-shortcuts-header $key
            # prettification hack for bash, because nix needs to escape dollar curly
            echo -e "''${_SHORTCUTS_PATHS[$key]}" | _denixify_escape
            _num_printed=$(( $_num_printed + 1 ))
        else
            _num_skipped=$(( $_num_skipped + 1 ))
        fi
    done
    if [ $_num_skipped -gt 0 ]; then
        echo -en "\n\e[93;2monly shortcuts within $_ENTRYPOINT_ENV_DIR are shown.\nto show $_num_skipped more, use\e[0m" "\e[96mshortcuts-all\e[0m\n\n"
    fi
}

function shortcuts-all() {
    shortcuts --all
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
    if [ "$name" == "nix-shell" ]; then
        _project_name=$(basename "$PWD")
    else
        _project_name="$name"
    fi
    export VIRTUAL_ENV=''${VIRTUAL_ENV-$USERCACHE/$_project_name-venv}
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
    ~/setup/bash/nix_shortcuts.nix.sh
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
let
  helpers = import ~/setup/nix/helpers.nix;
in helpers.mkShell [
] {
  buildInputs = [
  ];  # join lists with ++

  nativeBuildInputs = [
    ~/setup/bash/nix_shortcuts.nix.sh
  ];

  shellHook = $II
    echo-shortcuts \${__curPos.file}
  $II;  # join strings with +
}
EOF
}

function create-nix-flake-skeleton() {
    # https://nixos.wiki/wiki/Development_environment_with_nix-shell
    if [ -e flake.nix ]; then
        echo "ERROR: flake.nix already exists; doing nothing"
        return
    fi
    # HACK: bash variable substitution + nix import compat
    # this ensures that the outputted template script works in bash
    # but also that the .sh file can be imported in nix
    dollar_system=$(echo '$\{system\}'|tr -d '\\')
    II="'""'"
    cat > flake.nix<<EOF
{
  description = "optional description";

  nixConfig.bash-prompt = $II\033[1;32m\[[nix-develop:\[\033[36m\]\w\[\033[32m\]]\$\033[0m $II;

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/23.11-pre";
    whacked-setup = {
      url = "github:whacked/setup/a96d887ade4810d5db69a6e8d474d86c25bcad6e";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, flake-utils, whacked-setup }:
    flake-utils.lib.eachDefaultSystem
    (system:
    let
      pkgs = nixpkgs.legacyPackages.$dollar_system;
      whacked-helpers = import (whacked-setup + /nix/flake-helpers.nix) { inherit pkgs; };
    in {
      devShell = whacked-helpers.mkShell {
        flakeFile = __curPos.file;  # used to forward current file to echo-shortcuts
        includeScripts = [
          # e.g. for node shortcuts
          # (whacked-setup + /bash/node_shortcuts.sh)
        ];
      } {
        buildInputs = [
          # e.g.
          pkgs.nodejs
        ];

        shellHook = $II
          # e.g.
          alias dev='npm dev'
        $II;  # join strings with +
      };
    }
  );
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
