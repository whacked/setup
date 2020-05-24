with import <nixpkgs> {};

let
  fontsetup = (import ./fontsetup.nix);
in stdenv.mkDerivation {
  name = "vnc-with-wm-env";

  buildInputs = [
    cinnamon.nemo
    evince
    firefox
    git-cola
    glibcLocales
    gnome3.eog
    gnome3.file-roller
    graphviz
    i3
    icewm
    picom
    terminator
    tigervnc
  ]
  # ++ (import ./unfree.nix)
  ++ (import ./util.nix)
  ++ (import ./dev.nix)
  ++ (import ./cloud.nix)
  ++ fontsetup.buildInputs;
  shellHook = fontsetup.shellHook + ''

    # a quick way to set up a working oh-my-zsh config
    # when no .zshrc is available already. enter zsh
    # and (probably) dismiss the first-run menu, and
    # then `eval $zsh_quick_start`
    export zsh_quick_start='
      export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh
      export ZSH_THEME=tjkirch
      plugins=(git)
      source $ZSH/oh-my-zsh.sh
    ';

    # when run as-is without a config, as of picom 7.5
    # supplied in nixpkgs as of this commit, picom emits
    # a deluge of errors like
    # [ 05/12/20 21:40:15.408 paint_bind_tex ERROR ] Failed to find appropriate FBConfig for X pixmap
    # [ 05/12/20 21:40:15.408 paint_one ERROR ] Failed to bind texture for window 0x00200090.
    # ref https://github.com/yshui/picom/issues/407
    # a suggestion is to use picom v8 and run with
    # --experimental-backends;
    # using --experimental-backends on 7.5 silences the
    # errors, but leaves a trail when dragging windows.
    # discarding errors is still the most usable now.
    alias start-picom='picom 2>/dev/null'

  '';
}
