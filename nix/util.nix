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
    # croc  # no longer easy to use, back to wormhole
    crudini  # ini file CRUD
    curlie
    delta
    # difftastic  # supersede by delta
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
    hashdeep
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
    lf
    lsd
    magic-wormhole
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
    # nnn  # supercede with lf
    neovim
    # oh-my-zsh  # handoff to home-manager?
    # pdfdiff  # now marked insecure
    pigz
    procs
    # ranger  # supercede with lf
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
    zellij
    zoxide
    # zsh  # handoff to system/home-manager?
] ++ (
  if stdenv.isLinux then [
    atop
    btop
    gitwatch
    glibcLocales
    iotop
    iputils
    kpcli
    lm_sensors
    nfs-utils
    pdftk
    psmisc  # provides killall
    pulseaudio  # provides pactl
    sysstat  # provides sar
    util-linux  # provides cal
    # vifm  # supercede with lf
    xdotool
  ] else [

  ]
)

