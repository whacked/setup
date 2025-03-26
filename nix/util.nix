{ pkgs, ... }:
let
  vim = (pkgs.vim_configurable.override {
    python3 = pkgs.python3; # remove for remote
  });
  gitwatchSrc = pkgs.fetchFromGitHub {
    owner = "gitwatch";
    repo = "gitwatch";
    rev = "master";  # or a specific commit or tag
    hash = "sha256-Kw2Qc9LCRNd0jc6XjjhluAsk6f4q9KwYSyW5CSR7FMQ=";  # Replace with the correct SHA256
  };

  gitwatch = import "${gitwatchSrc}/gitwatch.nix" {
    runCommandNoCC = pkgs.runCommandNoCC;
    lib = pkgs.lib;
    makeWrapper = pkgs.makeWrapper;
    git = pkgs.git;
    openssh = pkgs.openssh;
    inotify-tools = pkgs.inotify-tools;
  };
in
with pkgs; [
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
    croc  # machine to machine secure file transfer
    crudini  # ini file CRUD
    curlie
    difftastic
    direnv
    dnsutils
    dos2unix
    dua
    emacs
    expect
    fd
    fdupes
    ffmpeg
    file
    findutils
    fzf
    git
    git-lfs
    gitAndTools.diff-so-fancy
    gitAndTools.gitui
    glances
    gnumake
    grc
    htop
    httpie
    icdiff
    imagemagick
    jiq
    jq
    jsonnet
    just
    keychain
    lazygit
    libtool
    lsd
    mc
    mercurial
    moreutils
    mosh
    navi
    # ncdu  # use dua for now; zig failing on macos
    netcat
    nettools
    nix-index
    nmap
    nnn
    # oh-my-zsh  # handoff to home-manager?
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
    watchexec
    websocat
    wget
    which
    # wuzz  # broken at 2023-02-06 14:00:33+08:00
    yq-go
    zoxide
    # zsh  # handoff to system/home-manager?
] ++ (
  if stdenv.isLinux then [
    btop
    gitwatch
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

