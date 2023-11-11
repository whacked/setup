activate-node-env() {
    if [ -e yarn.lock ]; then
        PM=yarn
        export PATH=$($PM bin):$PATH
    elif [ -e pnpm-lock.yaml ]; then
        PM=pnpm
        export PATH=$($PM bin):$PATH
    else
        PM=npm
        export PATH=$(npm prefix)/node_modules/.bin:$PATH
    fi
    if ! [ -e node_modules ]; then
        if [ -e package.json ]; then
            $PM install
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
