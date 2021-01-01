with import <nixpkgs> {};
[
    vscode
] ++ (
  if stdenv.isLinux then [
    google-chrome
    sublime3
    resilio-sync
    jetbrains.pycharm-professional
    jetbrains.idea-community
    android-studio
  ] else [

  ]
)
