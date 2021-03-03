activate-node-env() {
    export PATH=$(npm bin):$PATH
    if ! [ -e node_modules ]; then
        if [ -e package.json ]; then
            npm install .
        fi
    fi
}

