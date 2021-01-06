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
    xorg.xrandr
  ]
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

    function resize-display() {
        xrandr --fb $1
    }

    function start-vncserver() {
        if [ $# -lt 1 ]; then
            echo 'need <resolution> [password]'
            return
        fi
        if [ "x$DISPLAY" == "x" ]; then
            echo "export the DISPLAY variable before running this function"
            return
        fi
    
        _geometry=$1
        _force_password=$2
        if [ $(vncserver -list | awk '/X DISPLAY/ {getline; print $0}' | head -1 | awk '{print $1}') == "$DISPLAY" ]; then
            echo "$DISPLAY appears to be active. run 'vncserver -kill $DISPLAY' to terminate. exiting..."
            return
        fi
    
        mkdir -p $HOME/.vnc
        (cat <<'      EOF_XSTARTUP'
          #!/bin/sh
          unset SESSION_MANAGER
          unset DBUS_SESSION_BUS_ADDRESS
          if [ -x /etc/X11/xinit/xinitrc ]; then
            exec /etc/X11/xinit/xinitrc
          fi
          if [ -f /etc/X11/xinit/xinitrc ]; then
            exec sh /etc/X11/xinit/xinitrc
          fi
          [ -r $HOME/.Xresources ] && xrdb $HOME/.Xresources
          xsetroot -solid grey
          icewm &
          EOF_XSTARTUP
        ) | sed 's|^      ||' | cat > $HOME/.vnc/xstartup
        chmod +x $HOME/.vnc/xstartup
        if [ "x$_force_password" != "x" ]; then
            echo $_force_password | vncpasswd -f > $HOME/.vnc/passwd
            chmod 0600 $HOME/.vnc/passwd
        fi
        echo "geometry=$_geometry" > $HOME/.vnc/config
        vncserver -geometry $_geometry $DISPLAY
    }

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
