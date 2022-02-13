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
# */ rec { buildInputs = (with import <nixpkgs>{}; [ pastel ]); shellHook = ''

ICON_OK="🆗"
ICON_WARN="⚠️"

JSONNET_TEMPLATES_DIRECTORY=generators/templates

echoc() {  # unbuffered pastel so it retains ascii control chars for pipes
    unbuffer pastel paint -- $*
}

recommend() {
    if [ $# -eq 1 ]; then
        echo $(echoc magenta "recommendation: ")" $1"
        return
    fi
    echoc magenta "recommendations:"
    counter=0
    while [ $# -gt 0 ]; do
        counter=$(($counter + 1))
        echo "  $counter. $1"
        shift
    done
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
                recommend \
                    "maybe run $(echoc greenyellow $package_update_command)" \
                    "maybe run $(echoc greenyellow regenerate-package-json)" \
                    "run $(echoc greenyellow git add $package_json_path $jsonnet_template_path $package_lock_file) $(echoc green '&& git commit -v')"
            else
                echo " ($ICON_WARN  they are NOT at parity)"
                recommend \
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
                recommend \
                    "run $(echoc greenyellow git add $package_json_path) $(echoc green '&& git commit -v')"
            else
                _show-json-diff \
                    "current jsonnet template" "$(jsonnet $jsonnet_template_path)" \
                    "$package_json_path" "$(cat $package_json_path)"
                recommend \
                    "run $(echoc greenyellow jsonnet-parity-watcher $jsonnet_template_path $package_json_path) in one terminal" \
                    "run $(echoc greenyellow edit-package-jsonnet) in a separate terminal" \
                    "maybe run $(echoc greenyellow regenerate-package-json)" \
                    "run $(echoc greenyellow git add $package_json_path $jsonnet_template_path $package_lock_file) $(echoc green '&& git commit -v')"
                    # "edit $(echoc yellow $(_get-jsonnet-path)) or run $(echoc green regenerate-package-jsonnet) to seed the template"
            fi
            ;;
        ,template)
            echo "$ICON_WARN  $jsonnet_template_path is modified"
            _show-json-diff \
                "package.json" "$(cat $package_json_path)" \
                "$jsonnet_template_path" "$(jsonnet $jsonnet_template_path)"
            recommend "run $(echoc green regenerate-package-json) to regenerate $package_json_path from $jsonnet_template_path"
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
    package_file=package.json
    generator_file=$(_get-jsonnet-path)
    old_content=$(cat $generator_file)
    new_content=$(cat $package_file | jsonnet - | jsonnetfmt -)
    if [ "$new_content" == "$(cat $generator_file)" ]; then
        echo $generator_file output is at parity with $package_file, nothing to edit
    else
        package_file_relpath=$(realpath --relative-to=$(dirname $generator_file) $package_file)
        (echo "// (DELETE THIS COMMENT) output of this file should match $package_file_relpath" && cat $generator_file) |
            sponge $generator_file  # this prevents tee from clobbering
        # diff \
        #     --new-line-format="// %L" \
        #     --old-line-format="" \
        #     --unchanged-line-format="" \
        #     <(echo "$old_content") <(echo "$new_content") |
        #     (echo "// output of this file needs to match $(realpath $package_file)" && cat - $generator_file) |
        #     sponge $generator_file  # this prevents tee from clobbering
        echo "launching $EDITOR for $generator_file..."
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
    if [ $# -gt 1 ]; then
        echo enough
        baseline_file=$1
        contrast_file=$2
    else
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
    if [ ! -e $baseline_file ]; then
        echo "could not find baseline file at $baseline_file"
    fi
    if [ $num_errors -gt 0 ]; then
        echo errors
        return
    fi

    _test-jsonnet-at-parity $baseline_file $contrast_file
    if [ $? -eq 0 ]; then
        echo "$ICON_OK  $(echoc orange $baseline_file) and $(echoc yellow $contrast_file) are at parity"
        return
    fi
    watchexec -c -w . \
        "icdiff -L '$baseline_file' -L '$contrast_file' -N <(jsonnet '$baseline_file' | jq -S) <(jsonnet '$contrast_file' | jq -S)"
}

# --END-polyglot-hack-- ''; }
