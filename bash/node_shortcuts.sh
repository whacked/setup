activate-node-env() {
    export PATH=$(npm bin):$PATH
    if ! [ -e node_modules ]; then
        if [ -e package.json ]; then
            npm install .
        fi
    fi
}

diff-package-json() {
    assert-nargs 1+ $* || return
    # diff current package.json against the output of a package.json generator jsonnet file
    compare_jsonnet=$1
    source_json=${2-package.json}
    icdiff -N <(jsonnet $source_json | jq -S) <(jsonnet $compare_jsonnet | jq -S)
}
