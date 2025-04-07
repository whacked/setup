#! /usr/bin/env bash
function generate-gitignore() {
    USER_GITIGNORE_FILES=(".gitignore.custom" ".gitignore.local")
    touch .gitignore
    existing_sources=($(cat .gitignore | grep '^#\+ src:\+ h' | sort -u | sed -E 's|^#+ src: ||'))
    \rm .gitignore

    ONELINER='bash -c "$(cat .gitignore | sed -n '\''/^# ```bash/, /^# ```/p'\'' | sed '\''s/^# //'\'' | grep -v '\''^```'\''); generate-gitignore '"$@"'"'
    echo '### AUTO-POPULATED. DO NOT EDIT. generate-gitignore v2024-10-23.001' > .gitignore
    echo "### user ignores should go in: ${USER_GITIGNORE_FILES[*]}" >> .gitignore
    echo "### generated with: generate-gitignore $@" >> .gitignore
    echo "### 1-liner:" >> .gitignore
    echo "###   $ONELINER" >> .gitignore
    echo >> .gitignore

    # print my own source in comments. Compatible with bash and zsh.
    echo '# ```bash' >> .gitignore

    # Try multiple introspection commands in order of compatibility
    if declare -f generate-gitignore &>/dev/null; then
      declare -f generate-gitignore | sed 1d | sed 's|^|# |' >> .gitignore
    elif typeset -f generate-gitignore &>/dev/null; then
      typeset -f generate-gitignore | sed 1d | sed 's|^|# |' >> .gitignore
    elif functions generate-gitignore &>/dev/null; then
      functions generate-gitignore | sed 1d | sed 's|^|# |' >> .gitignore
    else
      echo "# (Function 'generate-gitignore' not found)" >> .gitignore
    fi

    echo '# ```' >> .gitignore

    echo >> .gitignore
    for existing_source in ${existing_sources[@]}; do
        echo "reloading $existing_source"
        # _read_gitignore_source
        echo "### src: $existing_source" >> .gitignore
        curl -s -L $existing_source >> .gitignore
        echo >> .gitignore
    done
    for f in $@; do
        SOURCE_URL=https://raw.githubusercontent.com/github/gitignore/master/${f%.gitignore}.gitignore
        if [[ " ${existing_sources[@]} " =~ " ${SOURCE_URL} " ]]; then
            continue
        fi
        echo "  loading $SOURCE_URL"
        # _read_gitignore_source
        echo "### src: $SOURCE_URL" >> .gitignore
        curl -s -L $SOURCE_URL >> .gitignore
        echo >> .gitignore
    done
    for user_file in "${USER_GITIGNORE_FILES[@]}"; do
        if [ -e "$user_file" ]; then
            echo "appending $user_file"
            echo "### $user_file" >> .gitignore
            cat "$user_file" >> .gitignore
            echo >> .gitignore
        fi
    done
}
