with import <nixpkgs> {};

let

  # NOTE:
  # 2023-05-20
  #   for older revision including pinned upstream packages building hug internally,
  #   see rev e8e2a06c84783017d49e4fdc3fdb54c5d88e35a5
  # 2024-06-19
  #   new setting required to make this run:
  #   pyproject = true;  # money line! false makes the thing build, and not run!

  custom_python3Packages = pkgs.python3Packages.override {
    overrides = self: super: {
      pydantic = super.pydantic.overrideAttrs (oldAttrs: rec {
        version = "1.10.16";
        pyproject = false;
        src = self.fetchPypi {
          pname = "pydantic";
          inherit version;
          hash = "sha256-i7OI9iRICa9p7jhJALELZ3pp8ZgP3GVepBlxDP/LVhA=";
        };
        patches = [];
        propagatedBuildInputs = [
          pkgs.python3Packages.poetry-core
          pkgs.python3Packages.setuptools
          pkgs.python3Packages.typing-extensions
        ];
        # Disable tests and other non-essential phases if they are problematic
        doCheck = false;
        doInstallCheck = false;
        pythonRemoveTestsDir = false;
        pythonCatchConflicts = false;
        pythonRemoveBinBytecodePhase = false;
        # Specifically ensure no pytest phase is executed
        pytestCheckPhase = null;
      });
    };
  };

  custom_fastApi = custom_python3Packages.fastapi.overrideAttrs (oldAttrs: {
    propagatedBuildInputs = (oldAttrs.propagatedBuildInputs or []) ++ [
      custom_python3Packages.pydantic
    ];
  });

  python3Packages_cachew = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "cachew";
    version = "0.11.0";
    src = pkgs.python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "4qjgvffInKRpKST9xbwwC2+m8h3ups0ZePyJLUU+KhA=";
    };

    buildInputs = [
      pkgs.python3Packages.appdirs
      pkgs.python3Packages.setuptools-scm
      pkgs.python3Packages.sqlalchemy
      pkgs.python3Packages.urlextract
    ];
  };

  python3Packages_promnesia = pkgs.python3.pkgs.buildPythonPackage rec {
    pname = "promnesia";
    version = "1.2.20230515";
    pyproject = true;

    src = pkgs.python3.pkgs.fetchPypi {
      inherit pname version;
      sha256 = "JmcHEnhrMXyUAV5JH4m50xN7rctCYd1qAH+yE042cSA=";
    };

    # for reference; this does exactly the same thing as the pip install;
    # even the rev tag is identical
    # src = pkgs.fetchFromGitHub {
    #    owner = "karlicoss";
    #    repo = "promnesia";
    #    rev = "v1.2.20230515";
    #    hash = "sha256-m+H47FyaRslROPAKCpjA9t8kI3qVBoqDKBFkPnDOTCk=";
    # };

    buildInputs = [
      sqlitebrowser
      pkgs.python3Packages.appdirs
      pkgs.python3Packages.pipdeptree
      pkgs.python3Packages.beautifulsoup4
      pkgs.python3Packages.httptools
      pkgs.python3Packages.logzero
      pkgs.python3Packages.lxml
      pkgs.python3Packages.mistletoe
      pkgs.python3Packages.more-itertools
      pkgs.python3Packages.python-dotenv
      pkgs.python3Packages.pytz
      pkgs.python3Packages.setuptools
      pkgs.python3Packages.setuptools-scm
      pkgs.python3Packages.sqlalchemy
      pkgs.python3Packages.tzlocal
      pkgs.python3Packages.urlextract
      pkgs.python3Packages.uvicorn
      pkgs.python3Packages.uvloop
      pkgs.python3Packages.watchfiles
      pkgs.python3Packages.websockets
      python3Packages_cachew
      custom_fastApi
    ];
  };
in stdenv.mkDerivation rec {
  name = "promnesia";
  env = buildEnv {
    name = name;
    paths = buildInputs;
  };
  buildInputs = [
    python3
    python3Packages_promnesia
  ] ++ python3Packages_promnesia.buildInputs;  # join lists with ++
  nativeBuildInputs = [
    ~/setup/bash/nix_shortcuts.nix.sh
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
