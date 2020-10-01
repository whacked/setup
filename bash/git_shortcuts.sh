function _read_gitignore_source() {
    SOURCE_URL=$1
    echo "### src: $SOURCE_URL"
    curl -s -L $SOURCE_URL
    echo
}

function generate-gitignore() {
    LOCAL_GITIGNORE_FILE=.gitignore.local
    touch .gitignore
    existing_sources=($(cat .gitignore | grep '^#\+ src: ' | sed -e 's|^#\+ src: ||'))
    \rm .gitignore
    echo '### AUTO-POPULATED. DO NOT EDIT' > .gitignore
    echo "### user ignores should go in $LOCAL_GITIGNORE_FILE" >> .gitignore
    echo >> .gitignore
    for existing_source in ${existing_sources[@]}; do
        _read_gitignore_source $existing_source >> .gitignore
    done
    for f in $@; do
        SOURCE_URL=https://raw.githubusercontent.com/github/gitignore/master/${f%.gitignore}.gitignore
        _read_gitignore_source $SOURCE_URL >> .gitignore
    done
    if [ -e .gitignore.local ]; then
        echo "### $LOCAL_GITIGNORE_FILE" >> .gitignore
        cat $LOCAL_GITIGNORE_FILE >> .gitignore
        echo >> .gitignore
    fi
}

