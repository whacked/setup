with import <nixpkgs> {};

let

  # thanks https://lazamar.co.uk/nix-versions/?package=python3.9-falcon&version=2.0.0&fullName=python3.9-falcon-2.0.0&keyName=python39Packages.falcon&revision=2cdd608fab0af07647da29634627a42852a8c97f&channel=nixpkgs-unstable#instructions
  old_pkgs = import (builtins.fetchTarball {
	  url = "https://github.com/NixOS/nixpkgs/archive/2cdd608fab0af07647da29634627a42852a8c97f.tar.gz";
  }) {};

  # not working well
  old_pkgs_ = import (builtins.fetchGit {
      # Descriptive name to make the store path easier to identify                
      name = "my-old-revision";                                                 
      url = "https://github.com/NixOS/nixpkgs/";                       
      ref = "refs/heads/nixpkgs-unstable";                     
      rev = "2cdd608fab0af07647da29634627a42852a8c97f";                                           
  }) {};                                                                           

  python39Packages_falcon = old_pkgs.python39Packages.falcon;
  python39Packages_hug = old_pkgs.python39Packages.hug;

  python39Packages_cachew = pkgs.python39.pkgs.buildPythonPackage rec {
    pname = "cachew";
    version = "0.9.0";
    src = pkgs.python39.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "19yqnm0rawg23d7m7rv7lz0f4gzz8r60bj7g4yf8xi1m1qk84awd";
    };

    buildInputs = [
      old_pkgs.python39Packages.urlextract
      old_pkgs.python39Packages.setuptools-scm
      old_pkgs.python39Packages.appdirs
      old_pkgs.python39Packages.sqlalchemy
    ];
  };
  python39Packages_promnesia = pkgs.python39.pkgs.buildPythonPackage rec {
    pname = "promnesia";
    version = "1.0.20210415";
    src = pkgs.python39.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "08vgcnz8j9ni3lwl8lbmnxmk9p3bp8ir8llakj9ckr1w1ljvlv7p";
    };

    buildInputs = [
      old_pkgs.python39Packages.beautifulsoup4
      old_pkgs.python39Packages.lxml
      old_pkgs.python39Packages.mistletoe
      old_pkgs.python39Packages.logzero
      old_pkgs.python39Packages.setuptools-scm
      old_pkgs.python39Packages.setuptools
      old_pkgs.python39Packages.appdirs
      old_pkgs.python39Packages.tzlocal
      old_pkgs.python39Packages.more-itertools old_pkgs.python39Packages.pytz
      old_pkgs.python39Packages.sqlalchemy
      old_pkgs.python39Packages.urlextract
      sqlitebrowser
      python39Packages_hug
      python39Packages_cachew
    ];
  };
in stdenv.mkDerivation rec {
  name = "promnesia";
  env = buildEnv {
    name = name;
    paths = buildInputs;
  };
  buildInputs = [
    python39
    python39Packages_promnesia
  ] ++ python39Packages_promnesia.buildInputs;  # join lists with ++
  nativeBuildInputs = [
    ~/setup/bash/nix_shortcuts.sh
  ];
  shellHook = ''
    alias demo='promnesia demo'
    alias serve='promnesia serve'
    alias index='promnesia index'
    alias doctor='promnesia doctor database'
    alias edit='vim ~/.config/promnesia/config.py'

    echo-shortcuts ${__curPos.file}
  '';  # join strings with +
}
