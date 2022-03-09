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
# */ rec { buildInputs = (with import <nixpkgs>{}; [     /*
# */   jsonnet jsonnet-bundler                           /*
# */ ]); shellHook = ''

_GLOBAL_JSONNET_VENDOR_PATH=$USERCACHE/jsonnet-libs

# set the JSONNET_PATH envvar globally so jsonnet will silently use it for --jpath
# /vendor is ksonnet / jsonnet-bundler style
export JSONNET_PATH=$_GLOBAL_JSONNET_VENDOR_PATH:$PWD/vendor''${JSONNET_PATH:+:}$JSONNET_PATH

if [ ! -e $_GLOBAL_JSONNET_VENDOR_PATH ]; then
    echo "INFO: creating jsonnet vendor directory at $_GLOBAL_JSONNET_VENDOR_PATH"
    mkdir -p $_GLOBAL_JSONNET_VENDOR_PATH
fi

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
        case $1 in
            git@*)
                repourl=$1
                outdir=$(echo ''${1#git@} | tr ':' '/')
                ;;

            https)
                repourl=$1
                outdir=''${1#https://}
                ;;

            *)
                repourl=https://$1
                outdir=$1
                ;;
        esac
        echo "RUN: git clone $repourl $outdir"
        git clone $repourl $outdir
    popd >/dev/null
}

# --END-polyglot-hack-- ''; }
