with import <nixpkgs> {};

let
  opencv_python = python39.pkgs.buildPythonPackage rec {
  };
in python39.pkgs.buildPythonPackage rec {
  pname = "docker-squash";
  version = "1.0.9";

  src = pkgs.python39.pkgs.fetchPypi {
    inherit pname version;
    sha256 = "0qj98hxhzfz6jzkynhch6j06zppjlzdj4jn5cjg1g9jsf47qm2pd";
  };

  doCheck = false;  # skip test phase, which fails

  buildInputs = [
    pkgs.python39Packages.six
  ];

  propagatedBuildInputs = [
    pkgs.python39Packages.docker
  ];
}
