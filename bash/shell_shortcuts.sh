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

