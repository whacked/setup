record-output-change() {
    # a function like `watch` but cares about
    # if and when the command output changed.
    # record-output-change -n <interval> [-o (output to file)] <command ...>
    # e.g.
    # record-output-change -n 1 -o ls -lrt
    INTERVAL=2
    OUTPUT_TO_FILE=
    while [[ $# -gt 0 ]]; do
        sw="$1"
        case $sw in
            -n)
                INTERVAL=$2
                shift
                shift
                ;;
            -o)
                OUTPUT_TO_FILE=1
                shift
                ;;
            *)
                break
                ;;
        esac
    done
    CMD="$*"

    old_cksum=
    while true; do
        output=$(eval $CMD)
        new_cksum=$(printf "$output" | cksum)
        if [ "$old_cksum" != "$new_cksum" ]; then
            old_cksum=$new_cksum
            col=$(( $(tput cols) - 0 ))
            if [ "x$OUTPUT_TO_FILE" != "x" ]; then
                ofile="$(date +%F_%H.%M.%S.%N).out"
                printf "$output" > $ofile
            else
                printf '%*s%s\r' $col "$(date '+%F %H:%M:%S.%N')"
                printf 'Every %.1fs: %s\n' $INTERVAL "$CMD"
                echo "$output"
            fi
        fi
        sleep $INTERVAL
    done
}

function stacktrace() {
    ### ref https://gist.github.com/akostadinov/33bb2606afe1b334169dfbf202991d36
    local i message="${1:-""}"
    local stack_size=${#FUNCNAME[@]}
    # to avoid noise we start with 1 to skip the get_stack function
    for (( i=1; i<$stack_size; i++ )); do
        local func="${FUNCNAME[$i]}"
        [ x$func = x ] && func=MAIN
        local linen="${BASH_LINENO[$(( i - 1 ))]}"
        local src="${BASH_SOURCE[$i]}"
        [ x"$src" = x ] && src=non_file_source
        printf "  - %d:  %-30s %s:%d\n" $i "$func(...)" $src $linen
    done
}

function assert-nargs() {
    parent_nargs=$(( $# - 1 ))
    if [ $parent_nargs -ne $1 ]; then
        red=`tput setaf 1`
        reset=`tput sgr0`
        echo "ERROR:  $red${FUNCNAME[1]}()$reset  needs $1 arguments; got $parent_nargs"
        echo "  stack (most recent call first)"
        stacktrace
        return -1
    fi
}

function export-var-or-default() {
    assert-nargs 2 $* || return
    var_name=$1
    var_value=${!var_name}
    default_value=$2
    if [ "x$var_value" == "x" ]; then
        echo "WARNING: using default value for variable: $(tput setaf 2)$var_name$(tput sgr0)=$default_value"
        export $var_name=$default_value
    else
        :
    fi
}

