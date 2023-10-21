/*/bin/true --BEGIN-polyglot-hack-- 2>/dev/null
# COMMENTARY:
# 
# nix/bash bilingual script; for background,
# see https://github.com/whacked/cow/blob/main/nix%20shellHack.md
# 
# TO USE, in your .nix expression, add something like:
#   let
#     jsonnetShortcutsPath = ~/setup/bash/jsonnet_shortcuts.nix.sh;
#     jsonnetShortcuts = (import jsonnetShortcutsPath);
# THEN:
#     buildInputs = [ ... ] ++ jsonnetShortcuts.buildInputs;
#     nativeBuildInputs = [ ... jsonnetShortcuts ... ];
#   OR:
#     shellHook = jsonnetShortcuts.shellHook + ...
#   OR:
#     shellHook = '' ... ${jsonnetShortcuts.shellHook} ... ''
# ALSO CONSIDER:
#     append-prompt-command check-package-template  # requires shell_shortcuts.sh
#     echo-shortcuts ${jsonnetShortcutsPath} # requires nix_shortcuts.sh
# 
# DEPENDENCES DECLARATION | NIX EXPRESSION:
# */ { pkgs ? import <nixpkgs> }:                                  /*
# */ rec { buildInputs = [                                         /*
# */   pkgs.jsonnet pkgs.jsonnet-bundler                           /*
# */   pkgs.coreutils                                              /*
# */ ]; shellHook = ''

if [ "x$USERCACHE" == "x" ]; then
    export USERCACHE=$(mktemp -d)
fi

_GLOBAL_JSONNET_VENDOR_PATH=$USERCACHE/jsonnet-libs

# set the JSONNET_PATH envvar globally so jsonnet will silently use it for --jpath
# /vendor is ksonnet / jsonnet-bundler style
# file default prevents throwing in strict variable check
export JSONNET_PATH=$PWD:$_GLOBAL_JSONNET_VENDOR_PATH:$PWD/vendor''${JSONNET_PATH:+:}''${JSONNET_PATH:-}

if [ ! -e $_GLOBAL_JSONNET_VENDOR_PATH ]; then
    echo "INFO: creating jsonnet vendor directory at $_GLOBAL_JSONNET_VENDOR_PATH"
    mkdir -p $_GLOBAL_JSONNET_VENDOR_PATH
fi


jsonnet-bundler-list() {
    \ls $_GLOBAL_JSONNET_VENDOR_PATH/github.com/*
}

jsonnet-bundler-install() {  # install to global vendor path using jsonnet-bundler
    # this hacks jsonnet-bundler to install everything into our designated
    # directory, $_GLOBAL_JSONNET_VENDOR_PATH by telling to to use $PWD, which
    # is also where we put jsonnetfile.json; by default. jb expects
    # jsonnetfile.json in $PWD, and packages to into $PWD/vendor
    if [ $# -lt 1 ]; then
        echo "ERROR: needs <package>"
        echo "EXAMPLE: jsonnet-bundler-install github.com/jsonnet-libs/xtd"
        return
    fi
    _package=$*

    echo "INFO: installing $_package"
    _jsonnet_bundler_vendor_dirname=$(basename $_GLOBAL_JSONNET_VENDOR_PATH)
    pushd $_GLOBAL_JSONNET_VENDOR_PATH >/dev/null
        touch jsonnetfile.json
        jb --jsonnetpkg-home=. install $*
    popd >/dev/null
}

jsonnet-repo-install() {  # install an arbitrary loadable jsonnet package
    if [ $# -lt 1 ]; then
        echo "ERROR: needs <package>"
        echo "EXAMPLE: jsonnet-repo-install git@github.com:someuser/somerepo"
        return
    fi
    pushd $_GLOBAL_JSONNET_VENDOR_PATH >/dev/null
        stripped_ext_path=''${1%.git}
        case $stripped_ext_path in
            git@*)
                repourl=$stripped_ext_path
                outdir=$(echo ''${stripped_ext_path#git@} | tr ':' '/')
                ;;

            https)
                repourl=$stripped_ext_path
                outdir=''${stripped_ext_path#https://}
                ;;

            *)
                repourl=https://$stripped_ext_path
                outdir=$stripped_ext_path
                ;;
        esac

        if [ -e $outdir ]; then
            echo "ERROR: already exists: $_GLOBAL_JSONNET_VENDOR_PATH/$outdir"
        else
            echo "RUN: git clone $repourl $outdir"
            git clone --depth 1 $repourl $outdir
            pushd $outdir > /dev/null
                echo "removing non-jsonnet files"
                find . -type f ! -path "./.git/*" ! -name "*.json*" -delete
            popd > /dev/null
        fi
    popd >/dev/null
}

# --END-polyglot-hack-- ''; }
