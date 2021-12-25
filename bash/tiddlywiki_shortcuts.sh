tid() {
    CWD=$PWD

    if [ "x$TIDDLYWIKI_TIDDLERS_PATH" != "x" ]; then
        cd $TIDDLYWIKI_TIDDLERS_PATH
    fi
    if [ $# -lt 1 ]; then
        tid $(sk)
        return
    fi
    
    # parse headers
    declare -A PROPERTIES
    cat $1 | sed '/^$/q' | while read line
    do
        key=$(echo $line | cut -d: -f1)
        if [ "x$key" = "x" ]; then
            continue
        fi
        PROPERTIES[$key]="$(echo $line | sed 's/^[^:]\+[: ]\+//')"
    done

    if [[ ${PROPERTIES[type]} =~ ^text.* ]]; then
        cat $1 | sed '0,/^$/d'
    else
        # treat as binary
        cat $1 | sed '0,/^$/d' | base64 -d
    fi

    cd $CWD
}

