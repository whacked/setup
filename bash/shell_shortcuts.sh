function record-output-change() {
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

cfRESET='\033[0m'      # tput setaf sgr0
cfBLACK='\033[0;30m'
cfRED='\033[0;31m'    # tput setaf 2
cfGREEN='\033[0;32m'
cfYELLOW='\033[0;33m'
cfBLUE='\033[0;34m'
cfPURPLE='\033[0;35m'
cfCYAN='\033[0;36m'
cfWHITE='\033[0;37m'

function echo-colored() {
    _color=$1
    shift
    echo -e "${_color}$*${cfRESET}"
}

function assert-nargs() {
    parent_nargs=$(( $# - 1 ))
    _error=false

    if [[ "$1" == *+ ]]; then
        if [ "$parent_nargs" -lt "${1%+}" ]; then
            _error=true
        fi
    elif [ "$parent_nargs" -ne "$1" ]; then
        _error=true
    fi
    if [ $_error = true ]; then
        echo -e "ERROR:  $cfRED${FUNCNAME[1]}()$cfRESET  needs $1 arguments; got $parent_nargs"
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
        echo -e "WARNING: using default value for variable: ${cfGREEN}$var_name${cfRESET}=$default_value"
        export $var_name=$default_value
    else
        :
    fi
}

function echo-export() {
    statement=$1
    statement_split=($(echo $statement | sed 's/=/ /'))
    echo -e "  ${cfYELLOW}export ${cfBLUE}${statement_split[0]}${cfRESET}=${cfCYAN}${statement_split[1]}${cfRESET}"
    export "$statement"
}

function run-all() {  # https://stackoverflow.com/a/10909842  https://unix.stackexchange.com/a/619159
    start_time=$(date +%s.%N)
    PID_LIST=()
    CMD_LIST=()
    for cmd in "$@"; do {
        color_number=$(( 6 - ${#PID_LIST[@]} % 6 + 30 ))
        echo -e "starting: \"\\033[0;${color_number}m${cmd}${cfRESET}\"";
        CMD_LIST+=("$cmd")
        eval $cmd &> >( sed -u $'s|^|\033[0m] |' | sed -u $'s|^|\033[0;'$color_number'm'"$cmd"'|' | sed -u $'s|^|[|') &
        pid=$!
        PID_LIST+=("$pid")
    } done

    function kill-subshells() {
        echo "received interrupt..."
        for i in $(seq ${#PID_LIST[@]}); do
            pid=${PID_LIST[$(( $i - 1 ))]}
            cmd=${CMD_LIST[$i]}
            color_number=$(( $i % 6 + 30 ))
            echo $color_number
            echo "kill -- -${pid}: \\033[0;${color_number}m${cmd}${cfRESET}"
            kill -- -$pid
        done
    }

    trap kill-subshells SIGINT
    echo -e "\\033[46m${#PID_LIST[@]} processes have started:${cfRESET} $PID_LIST";
    for pid in "${PID_LIST[@]}"; do
        wait "$pid"
    done

    end_time=$(date +%s.%N)
    echo -e "\\033[43m*** ALL DONE ***${cfRESET} ($( echo $end_time - $start_time | bc ))";
}

function append-prompt-command() {
    func=$1
    cleaned_command=$(echo $PROMPT_COMMAND | tr ';' '\n' | grep -v $func | paste -s -d ';' -)
    export PROMPT_COMMAND=$cleaned_command${cleaned_command:+;}$func
}

function append-to-path() {
    path_var=$1
    path_value=$2
    export $path_var=$(echo -n ${!path_var}":$path_value" | tr ':' '\n' | awk '!x[$0]++' | paste -s -d':')
}

function pip-add-require() {
    assert-nargs 1 $* || return
    package=$1
    _pip_requirements_file=
    for candidate in req.txt requirements.txt; do
        if [ -e $candidate ]; then
            _pip_requirements_file=$candidate
            break
        fi
    done
    if [ "x$_pip_requirements_file" = "x" ]; then
        echo "ERROR: could not locate requirements file"
        return
    fi
    pip install $package
    if [ $? -eq 0 ]; then
        ( cat $_pip_requirements_file| grep -v "$package.=" ; pip freeze | grep $package ) | sort | sponge $_pip_requirements_file
    else
        echo "ERROR: failed to install package $package"
    fi
}


function create-makefile-skeleton() {
    if [ -e Makefile ]; then
        echo "ERROR: Makefile already exists; doing nothing"
        return
    fi
    cat > Makefile<<EOF
include \$(HOME)/setup/include/Makefile
EOF
}
