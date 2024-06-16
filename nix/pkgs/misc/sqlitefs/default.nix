{ rustPlatform, stdenv, pkgs }:

rustPlatform.buildRustPackage rec {
  pname = "sqlitefs";
  version="0.1.0";
  goPackagePath = "github.com/narumatt/sqlitefs";

  buildInputs = [
    pkgs.fuse
    pkgs.pkg-config
  ];  # join lists with ++

  nativeBuildInputs = [
    pkgs.fuse
    pkgs.pkg-config
  ];

  src = pkgs.fetchFromGitHub {
    owner = "narumatt";
    repo = "sqlitefs";
    rev = "master";
    sha256 = "03mk7q47smbxj86qsilz0yh7kbw0yb6pfw0ypnrn16xiavwdbq7s";
  };

  cargoSha256 = "0z82zgkg6n3vwy8plhik8zw3q898xdg0m2mx8kddp5an2f7nji25";

  meta = with pkgs.lib; {
    description = ''read-write enabled fuse mountable sqlitedb'';
    downloadPage = "https://github.com/narumatt/sqlitefs";
    inherit version;
  };
}

