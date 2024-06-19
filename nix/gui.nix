# desktop
{ pkgs, ... }:

let
  # veracrypt dropped truecrypt volume support in the latest version (1.26.7)
  # pin it to 23.11 for now
  pinnedNixPkgs = import (pkgs.fetchFromGitHub {
    owner = "NixOS";
    repo = "nixpkgs";
    rev = "057f9aecfb71c4437d2b27d3323df7f93c010b7e";
    hash = "sha256-MxCVrXY6v4QmfTwIysjjaX0XUhqBbxTWWB4HXtDYsdk=";
  }) {};
  veracrypt = pinnedNixPkgs.veracrypt;
in
with pkgs; [
    conky
    hack-font
    gnome3.eog
    graphviz
    evince
    firefox
    git-cola
    tilix
    veracrypt
    vlc
    xclip
    xsel
]
