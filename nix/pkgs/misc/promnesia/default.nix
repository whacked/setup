with import <nixpkgs> {};

let

  # NOTE:
  # 2023-05-20
  #   for older revision including pinned upstream packages building hug internally,
  #   see rev e8e2a06c84783017d49e4fdc3fdb54c5d88e35a5

  python310Packages_cachew = pkgs.python310.pkgs.buildPythonPackage rec {
    pname = "cachew";
    version = "0.11.0";
    src = pkgs.python310.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "4qjgvffInKRpKST9xbwwC2+m8h3ups0ZePyJLUU+KhA=";
    };

    buildInputs = [
      pkgs.python310Packages.appdirs
      pkgs.python310Packages.setuptools-scm
      pkgs.python310Packages.sqlalchemy
      pkgs.python310Packages.urlextract
    ];
  };
  python310Packages_promnesia = pkgs.python310.pkgs.buildPythonPackage rec {
    pname = "promnesia";
    version = "1.2.20230515";
    src = pkgs.python310.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "JmcHEnhrMXyUAV5JH4m50xN7rctCYd1qAH+yE042cSA=";
    };

    buildInputs = [
      sqlitebrowser
      pkgs.python310Packages.appdirs
      pkgs.python310Packages.beautifulsoup4
      pkgs.python310Packages.fastapi
      pkgs.python310Packages.httptools
      pkgs.python310Packages.logzero
      pkgs.python310Packages.lxml
      pkgs.python310Packages.mistletoe
      pkgs.python310Packages.more-itertools
      pkgs.python310Packages.python-dotenv
      pkgs.python310Packages.pytz
      pkgs.python310Packages.setuptools
      pkgs.python310Packages.setuptools-scm
      pkgs.python310Packages.sqlalchemy
      pkgs.python310Packages.tzlocal
      pkgs.python310Packages.urlextract
      pkgs.python310Packages.uvicorn
      pkgs.python310Packages.uvloop
      pkgs.python310Packages.watchfiles
      pkgs.python310Packages.watchfiles
      pkgs.python310Packages.websockets
      python310Packages_cachew
    ];
  };
in stdenv.mkDerivation rec {
  name = "promnesia";
  env = buildEnv {
    name = name;
    paths = buildInputs;
  };
  buildInputs = [
    python310
    python310Packages_promnesia
  ] ++ python310Packages_promnesia.buildInputs;  # join lists with ++
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
