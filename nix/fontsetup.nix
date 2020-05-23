with import <nixpkgs> {};

stdenv.mkDerivation rec {
    name = "fontsetup-env";
    env = buildEnv {
        name = name;
        paths = buildInputs;
    };

    buildInputs = [
        dejavu_fonts
        fontconfig
        inconsolata
        ubuntu_font_family
    ];

    shellHook = ''
      function setup-fonts() {
        _fonts_dir=$HOME/.local/share/fonts
        mkdir -p $_fonts_dir
        if [ ! -e $_fonts_dir/fonts.conf ]; then
            cp ${fontconfig.out}/etc/fonts/fonts.conf $_fonts_dir/fonts.conf
        fi
        export FONTCONFIG_FILE=$_fonts_dir/fonts.conf
        _ttf_dirs=(
          ${dejavu_fonts.out}/share/fonts/truetype/
          ${inconsolata.out}/share/fonts/truetype/
          ${ubuntu_font_family.out}/share/fonts/ubuntu/
        )
        for fpath in $(find ''${_ttf_dirs[@]} -name '*.ttf'); do
          ln -s $fpath $_fonts_dir/$(basename $fpath) 2>/dev/null || true
        done
        fc-cache -fv
      }
    '';
}

