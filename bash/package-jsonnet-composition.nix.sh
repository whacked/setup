/*/bin/true --BEGIN-polyglot-hack-- 2>/dev/null
# COMMENTARY:
# 
# this file needs to be `import`-ed into another nix expression to be added to
# a nix shell environment.  it exposes these properties:
# .shellHook    # the bash-compatible logic
# .buildInputs  # the dependencies for the shellHook
# 
# but since this file is almost entirely bash, we use a polyglot-hack to make
# this file nix- and bash- compatible.  You can thus `source $this_file` to
# include the functions in any bash environment -- provided that you have all
# the declared dependencies
# 
# */ rec { buildInputs = (with import <nixpkgs>{}; [ pastel gron fswatch vim ]); shellHook = ''

ICON_OK="🆗"
ICON_WARN="⚠️"

JSONNET_TEMPLATES_DIRECTORY=generators/templates
IS_VIM_TERMINAL_AVAILABLE=$(vim --version | fmt -w1 | grep '^+terminal$')

echoc() {  # unbuffered pastel so it retains ascii control chars for pipes
    unbuffer pastel paint -- $*
}

print-recommendations() {
    if [ $# -eq 1 ]; then
        echo $(echoc magenta "recommendation: ")" $1"
        return
    fi
    echoc magenta "recommendations:"
    counter=0
    while [ $# -gt 0 ]; do
        if [ "x$1" == "x" ]; then
            shift
            continue
        fi
        counter=$(($counter + 1))
        echo "  $counter. $1"
        shift
    done
}

_recommendation_command_buffer=
_set-recommendation-command() {
    _recommendation_command_buffer="$*"
    if [ "x$_recommendation_command_buffer" != "x" ]; then
        echo "run $(echoc hotpink accept-recommendations) to run "$(echoc greenyellow "$*")
    fi
}

accept-recommendations() {
    if [ "x$_recommendation_command_buffer" == "x" ]; then
        echo "there is no active recommendation"
    else
        echo "accepting recommendation: "$(echoc yellow "$_recommendation_command_buffer")
        eval $_recommendation_command_buffer
        _recommendation_command_buffer=
    fi
}

_get-jsonnet-path() {
    echo $JSONNET_TEMPLATES_DIRECTORY/package.jsonnet
}

_show-json-diff() {  # <old-name> <old-json> <new-name> <new-json>
    old_name=$1
    old_json=$2
    new_name=$3
    new_json=$4

    diff_content=$(icdiff -L "$old_name" -L "(modified) $new_name" -N <(echo "$old_json" | jq -S) <(echo "$new_json" | jq -S))

    if [ $(echo "$diff_content" | wc -l) -eq 1 ]; then
        echo -n "$ICON_OK  "
        echoc lime "$old_name matches $new_name"
    else
        echo -n "$ICON_WARN  "
        echoc red "$new_name has diverged from $old_name"
        echo "$diff_content"
    fi
}

diff-against-head() {
    file_path=$1
    file_path_in_git=$(git rev-parse --show-prefix)$file_path
    echo _show-json-diff \
        "$file_path_in_git in git" "$(git show HEAD:$file_path_in_git)" \
        "latest $file_path" "$(cat $file_path)"
}

_test-jsonnet-at-parity() {
    diff <(jsonnet $1) <(jsonnet $2) > /dev/null
}

create-package-template-file() {
    jsonnet_template_path=$(_get-jsonnet-path)
    mkdir -p $(dirname $jsonnet_template_path)
    echo "🏗️  $(echoc lime creating template file at $jsonnet_template_path)"
    regenerate-package-jsonnet
}

check-package-template() {  # detect + show changes in package json/jsonnet; when in doubt, run this ℹ️
    _set-recommendation-command  # reset on every check

    package_json_path=package.json
    jsonnet_template_path=$(_get-jsonnet-path)

    if [ ! -e $package_json_path ]; then
        echo "$(echoc yellow no package file found at $package_json_path); nothing to check" >&2
        return
    fi

    if [ ! -e $jsonnet_template_path ]; then
        echo "$(echoc yellow no template found at $jsonnet_template_path); run $(echoc greenyellow create-package-template-file) to seed from $package_json_path" >&2
        return
    fi

    # detect updated files
    maybe_changed_package=$(git ls-files -m $package_json_path | sed 's/.*/package/')
    maybe_changed_jsonnet=$(git ls-files -m $jsonnet_template_path | sed 's/.*/template/')

    if [ -e yarn.lock ]; then
        package_lock_file=yarn.lock
        package_update_command='yarn'
    else
        package_lock_file=package.json.lock
        package_update_command='npm install'
    fi
    case "$maybe_changed_package,$maybe_changed_jsonnet" in
        ,)
            ;;
        package,template)
            echo -n -e 'both '$(echoc yellow $package_json_path)' and '$(echoc yellow $jsonnet_template_path)' are different from git HEAD'
            _test-jsonnet-at-parity $package_json_path $jsonnet_template_path

            if [ $? -eq 0 ]; then
                echo " ($ICON_OK they are at parity)"
                print-recommendations \
                    "maybe run $(echoc greenyellow $package_update_command)" \
                    "maybe run $(echoc greenyellow regenerate-package-json)" \
                    "run $(echoc greenyellow git add $package_json_path $jsonnet_template_path $package_lock_file) $(echoc green '&& git commit -v')"
                _set-recommendation-command "$package_update_command; regenerate-package-json; git add $package_json_path $jsonnet_template_path $package_lock_file && git commit -v"
            else
                echo " ($ICON_WARN  they are NOT at parity)"
                print-recommendations \
                    "run $(echoc greenyellow jsonnet-parity-watcher) in one terminal" \
                    "edit $(echoc orange $jsonnet_template_path) separately (e.g. $(echoc greenyellow edit-package-jsonnet))" \
                    "maybe run $(echoc greenyellow regenerate-package-json) (to enforce package.json formatting)" \
                    "run $(echoc greenyellow git add $package_json_path $jsonnet_template_path $package_lock_file) $(echoc green '&& git commit -v')"
            fi

            ##package_json_in_git=$(git rev-parse --show-prefix)$package_json_path
            ##_show-json-diff \
            ##    "package.json in git" "$(git show HEAD:$package_json_in_git)" \
            ##    "latest package.jsonnet" "$(jsonnet $jsonnet_template_path)"
            ##_show-json-diff \
            ##    "package.json" "$(cat $package_json_path)" \
            ##    "package.jsonnet" "$(jsonnet $jsonnet_template_path)"
            ;;
        package,)
            # echo "$ICON_WARN  $package_json_path is modified"
            _test-jsonnet-at-parity $package_json_path $jsonnet_template_path
            if [ $? -eq 0 ]; then
                echo "$package_json_path updated; $ICON_OK at parity with $jsonnet_template_path"
                print-recommendations \
                    "run $(echoc greenyellow git add $package_json_path) $(echoc green '&& git commit -v')"
                _set-recommendation-command "git add $package_json_path && git commit -v"
            else
                _show-json-diff \
                    "current jsonnet template" "$(jsonnet $jsonnet_template_path)" \
                    "$package_json_path" "$(cat $package_json_path)"
                ALTERNATIVE_RECOMMENDATION="run $(echoc greenyellow jsonnet-parity-watcher --template) in one terminal + $(echoc greenyellow edit-package-jsonnet) in another terminal"
                if [ "x$IS_VIM_TERMINAL_AVAILABLE" == "x" ]; then
                    VIM_WATCHER_RECOMMENDATION=
                else
                    VIM_WATCHER_RECOMMENDATION="run $(echoc greenyellow edit-package-jsonnet --vim-watcher)"
                    ALTERNATIVE_RECOMMENDATION="OR $ALTERNATIVE_RECOMMENDATION"
                fi
                print-recommendations \
                    "$VIM_WATCHER_RECOMMENDATION" \
                    "$ALTERNATIVE_RECOMMENDATION" \
                    "maybe run $(echoc greenyellow regenerate-package-json)" \
                    "run $(echoc greenyellow git add $package_json_path $jsonnet_template_path $package_lock_file) $(echoc green '&& git commit -v')"
                    # "edit $(echoc yellow $(_get-jsonnet-path)) or run $(echoc green regenerate-package-jsonnet) to seed the template"
                # TODO add recommendation command?
                # _set-recommendation-command ""
            fi
            ;;
        ,template)
            echo "$ICON_WARN  $jsonnet_template_path is modified"
            _show-json-diff \
                "package.json" "$(cat $package_json_path)" \
                "$jsonnet_template_path" "$(jsonnet $jsonnet_template_path)"
            print-recommendations "run $(echoc green regenerate-package-json) to regenerate $package_json_path from $jsonnet_template_path"
            ;;
    esac
}

_update-with-patch() {
    target_file=$1
    patch_content=$2

    patch_string=$(diff -u $target_file <(echo "$patch_content"))
    echoc yellow "applying patch; copy-paste the command below to reverse it."
    echoc orange "patch -R $target_file <<'EOF__UNDO_PATCH'"
    echo "$patch_string"
    echoc orange "EOF__UNDO_PATCH"
    echo "$patch_string" | patch $target_file
}

regenerate-package-jsonnet() {  # update package.jsonnet so it matches package.json
    source_file=package.json
    target_file=$(_get-jsonnet-path)
    new_content=$(cat $source_file | jsonnet - | jsonnetfmt -)
    if [ ! -e $target_file ]; then
        echo "$new_content" | tee $target_file
    elif [ "$new_content" == "$(cat $target_file)" ]; then
        return
    else
        _update-with-patch "$target_file" "$new_content"
    fi
}

edit-package-jsonnet() {  # append the package.json diff to package.jsonnet and launch $EDITOR
    VIM_WATCHER_MODE=
    if [ "$1" == "--vim-watcher" ]; then
        if [ "x$IS_VIM_TERMINAL_AVAILABLE" != "x" ]; then
            VIM_WATCHER_MODE=1
        else
            echo "WARNING: vim terminal feature not available" >&2
        fi
    fi

    package_file=package.json
    generator_file=$(_get-jsonnet-path)
    old_content=$(cat $generator_file)
    new_content=$(cat $package_file | jsonnet - | jsonnetfmt -)
    if [ "$new_content" == "$(cat $generator_file)" ]; then
        echo $generator_file output is at parity with $package_file, nothing to edit
    elif [ "$VIM_WATCHER_MODE" == "1" ]; then
        generator_file_abspath=$(realpath $generator_file)
        package_file_abspath=$(realpath $package_file)
        # matches jsonnet-parity-watcher
        diff_size=$(icdiff <(jsonnet "$generator_file" | jq -S) <(cat "$package_file" | jq -S) | wc -l)

        echo "launching $EDITOR for $generator_file..."
        vim \
            -c "ter nix-shell --run \"jsonnet-parity-watcher --vim-watcher\"" \
            -c "resize $(($diff_size + 4))" \
            -c 'wincmd p' \
            -c "vsplit $package_file" \
            -c "vsplit $generator_file" \
            <(
                echo "// output of $generator_file_abspath"
                echo "// should match $package_file_abspath"
                diff <(jsonnet "$generator_file" | gron) <(gron "$package_file") |
                      grep '[|<>]' |
                      cut -c 3- |
                      gron --ungron |
                      cut -c 3- |
                      grep -v '^$'
            ) \
            -c 'wincmd r' \
            -c 'wincmd j' \
            -c 'wincmd h' \
            -c 'wincmd h'
    elif [ "$EDITOR" == "vim" ]; then
        diff --side-by-side --expand-tabs <(echo "$old_content") <(echo "$new_content") | grep '[|<>]' -C 3
        (
            echo "// output of $generator_file"
            echo "// should match $package_file"
            diff --side-by-side --expand-tabs <(jsonnet "$generator_file" | jq -S) <(cat "$package_file" | jq -S) | grep '[|<>]' -C 3
            diff --side-by-side --expand-tabs <(cat "$package_file" | jq -S) <(jsonnet "$generator_file" | jq -S) | grep '[|<>]' -C 3
        ) | $EDITOR - -c "vs $generator_file"
    else
        $EDITOR $generator_file
    fi
}

regenerate-package-json() {
    source_file=$(_get-jsonnet-path)
    target_file=package.json
    new_content=$(jsonnet $source_file | jq -S)
    if [ "$new_content" == "$(cat $target_file)" ]; then
        return
    else
        _update-with-patch "$target_file" "$new_content"
    fi
}

jsonnet-parity-watcher() {

    VIM_WATCHER_MODE=
    case $1 in
        --vim-watcher)
            VIM_WATCHER_MODE=1
            shift
            if [ $# -gt 0 ]; then
                echo "ERROR: vim watcher mode cannot take additional arguments" >&2
                return
            fi
            baseline_file=$(_get-jsonnet-path)
            contrast_file=package.json
            ;;

        --template)
            baseline_file=$(_get-jsonnet-path)
            contrast_file=package.json
            ;;

        --package)
            baseline_file=package.json
            contrast_file=$(_get-jsonnet-path)
            ;;
    esac

    if [ $# -gt 1 ]; then
        baseline_file=$1
        contrast_file=$2
    elif [ "x$baseline_file" == "x" ] || [ "x$contrast_file" == "x" ]; then
        # by default, we want to use the earlier file as baseline, later file as contrast
        sorted_files=($(ls -1rt package.json $(_get-jsonnet-path)))
        if [ $# -eq 1 ]; then
            baseline_file=$1
            for f in ''${sorted_files[@]}; do
                if [ "$f" != "$baseline_file" ]; then
                    contrast_file=$f
                    break
                fi
            done
        else
            baseline_file=''${sorted_files[0]}
            contrast_file=''${sorted_files[1]}
        fi
    fi

    num_errors=0
    if [ ! -e $baseline_file ]; then
        echo "could not find baseline file at $baseline_file"
    fi
    if [ ! -e $contrast_file ]; then
        echo "could not find contrast_file at $contrast_file"
    fi
    if [ $num_errors -gt 0 ]; then
        echo errors
        return
    fi

    DIFFCMD="icdiff -L '$baseline_file' -L '$contrast_file' -N <(jsonnet '$baseline_file' | jq -S) <(jsonnet '$contrast_file' | jq -S)"
    if [ "x$IS_VIM_TERMINAL_AVAILABLE" == "x" ]; then
        echo "WARNING: vim terminal feature not available" >&2
        VIM_WATCHER_MODE=
    fi
    if [ "$VIM_WATCHER_MODE" == "1" ]; then
        while true; do
            diff_content=$(eval $DIFFCMD)
            if [ $(echo "$diff_content" | wc -l) -eq 1 ]; then
                break
            else
                clear
                echo "$diff_content"
            fi
            fswatch --latency=0.1 --one-event $baseline_file $contrast_file &>/dev/null
        done
        clear
        echo "at parity!"
        echo "  $baseline_file"
        echo "  $contrast_file"
        echo "save the changes and exit!"
    else
        _test-jsonnet-at-parity $baseline_file $contrast_file
        if [ $? -eq 0 ]; then
            echo "$ICON_OK  $(echoc orange $baseline_file) and $(echoc yellow $contrast_file) are at parity"
            return
        fi
        watchexec -c -w . "$DIFFCMD"
    fi
}

# --END-polyglot-hack-- ''; }
