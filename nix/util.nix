with import <nixpkgs> {};
let
  vim = (vim_configurable.override { python = python3; });
in
[
    findutils
    gnumake
    iputils
    jq
    jsonnet
    netcat
    nfs-utils
    rsync
    glibcLocales

    bat
    broot
    ansible
    autoconf
    automake
    # deprecate
    #bazaarTools
    binutils
    bzip2
    crudini  # ini file CRUD
    direnv
    dnsutils
    dos2unix
    emacs
    expect
    fasd
    fdupes
    ffmpeg
    file
    git
    htop
    imagemagick
    keychain
    mc
    mercurial
    moreutils
    mosh
    nettools
    nmap
    # now marked insecure
    #pdfdiff
    pdftk
    pigz
    rclone
    ripgrep
    rlwrap
    skim
    sqlite
    squashfsTools
    subversion
    tcpdump
    tig
    tokei
    tmux
    unzip
    vim
    wget
    which
    xdotool
    zsh
    oh-my-zsh
]
