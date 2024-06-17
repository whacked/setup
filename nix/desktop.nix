{ pkgs, ... }:

with pkgs; [
    # fixes Gtk-WARNING "Locale not supported by C library"
    glibcLocales

    haskellPackages.ghc
    xmonad-with-packages
    ## leave this to cabal for now
    # haskellPackages.xmonad
    # haskellPackages.xmonad-extras
    # haskellPackages.xmonad-contrib
    ## these are required to build xmonad from cabal
    ## order is important :-(
    # cabal install alex happy c2hs
    alsaLib
    # error: 'xlibsWrapper' has been replaced by its constituents
    # but this most likely is needed somewhere; keeping for reference
    # xlibsWrapper
    pkg-config
    xorg.libXext
    xorg.libXrandr
    xorg.libXinerama
    xorg.libXScrnSaver
    haskellPackages.cabal-install
    nerdfonts

    rofi
    shutter
    xorg.xkbcomp
    xorg.xmodmap
    xorg.xmessage

    acpi
    cinnamon.nemo
    wmctrl
    xfce.thunar

    wl-clipboard
]
