{ pkgs, ... }:

with pkgs; [
    vscode
] ++ (
  if pkgs.stdenv.isLinux then [
    google-chrome
    sublime3
    resilio-sync
    jetbrains.pycharm-professional
    jetbrains.idea-community
    android-studio
  ] else [

  ]
)
