function generate-gitignore() {
    LOCAL_GITIGNORE_FILE=.gitignore.local
    \rm .gitignore
    echo '### AUTO-POPULATED. DO NOT EDIT' > .gitignore
    echo "### user ignores should go in $LOCAL_GITIGNORE_FILE" >> .gitignore
    echo >> .gitignore
    for f in $@; do
        SOURCE_URL=https://raw.githubusercontent.com/github/gitignore/master/${f%.gitignore}.gitignore
        echo "### src: $SOURCE_URL" >> .gitignore
        curl -s -L $SOURCE_URL >> .gitignore
        echo >> .gitignore
    done
    if [ -e .gitignore.local ]; then
        echo "### $LOCAL_GITIGNORE_FILE" >> .gitignore
        cat $LOCAL_GITIGNORE_FILE >> .gitignore
        echo >> .gitignore
    fi
}

