_matching_files=$(cat config.nix | grep import | sed 's|.\+import \(.\+nix\).*|\1|')
_packages=$(cat $_matching_files | awk '/^\[/,EOF' | grep '^ \+[_a-zA-Z0-9]\+$' | sort)
echo "=== MATCHING FILES ==="
echo $_matching_files
echo "=== PACKAGES ==="
echo $_packages | tr ' ' '\n'
for package in $_packages; do
    nix-env -i $package
done
