function echo-shortcuts() {
    target_file=${1-default.nix}
    cat $target_file | grep --color '\<\(function\|alias\)\> .\+'
}
