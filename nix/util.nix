with import <nixpkgs> {};
let
  vim = (vim_configurable.override {
    python = python3; # remove for remote
  });
in
[
    ansible
    ansifilter
    autoconf
    automake
    bashplotlib
    bat
    # bazaarTools  # deprecated
    binutils
    broot
    bzip2
    coreutils
    crudini  # ini file CRUD
    curlie
    difftastic
    direnv
    dnsutils
    dos2unix
    emacs
    expect
    fasd
    fd
    fdupes
    ffmpeg
    file
    findutils
    git
    gitAndTools.diff-so-fancy
    gitAndTools.gitui
    glances
    gnumake
    grc
    htop
    httpie
    icdiff
    imagemagick
    jq
    jsonnet
    keychain
    libtool
    lsd
    mc
    mercurial
    moreutils
    mosh
    navi
    ncdu
    netcat
    nettools
    nix-index
    nmap
    nnn
    oh-my-zsh
    # pdfdiff  # now marked insecure
    pigz
    procs
    ranger
    rclone
    ripgrep
    rlwrap
    rq
    rsync
    skim
    sqlite
    squashfsTools
    subversion
    tcpdump
    termtosvg
    tig
    tldr
    tmux
    tmux-xpanes
    tokei
    ttyplot
    unzip
    vim
    wget
    which
    wuzz
    yq-go
    zsh
] ++ (
  if stdenv.isLinux then [
    atop
    bpytop
    glibcLocales
    iotop
    iputils
    kpcli
    nfs-utils
    pdftk
    sysstat  # provides sar
    vifm
    xdotool
  ] else [

  ]
)

