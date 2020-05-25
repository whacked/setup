if [ $DEBUG_LEVEL -gt 0 ]; then
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
        echo " - setting up virtualenv in $VIRTUAL_ENV..."
        python -m venv $VIRTUAL_ENV
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
