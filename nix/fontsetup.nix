with import <nixpkgs> {};

stdenv.mkDerivation rec {
    name = "fontsetup-env";
    env = buildEnv {
        name = name;
        paths = buildInputs;
    };

    buildInputs = [
        dejavu_fonts
        inconsolata
        fontconfig
    ];

    shellHook = ''
      function setup-fonts() {
          mkdir -p $HOME/.fonts
          _font_dirs=(
            ${pkgs.dejavu_fonts.out}/share/fonts/truetype/
            ${pkgs.inconsolata.out}/share/fonts/truetype/
          )
          for fpath in $(find ''${_font_dirs[@]} -name '*.ttf'); do
              fontfile=$(basename $fpath)
              target=$HOME/.fonts/$fontfile
              ln -s $fpath $target 2>/dev/null || true
          done
          fc-cache -fv
      }
    '';
}

