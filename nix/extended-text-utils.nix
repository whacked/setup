# packages related to knowledge management
{ pkgs, ... }:

let
  ck         = pkgs.callPackage (import ./pkgs/development/tools/ck/default.nix)  {};
  tuitab     = pkgs.callPackage (import ./pkgs/misc/tuitab/default.nix)           {};
  tidyViewer = pkgs.callPackage (import ./pkgs/misc/tidy-viewer/default.nix)               {};
  beadsRust  = pkgs.callPackage (import ./pkgs/misc/beads-rust/default.nix)       {};
in
with pkgs; [
  tuitab
  beadsRust
  tidyViewer
]
# ck linux build currently broken; darwin only
++ (if pkgs.stdenv.isDarwin then [ ck ] else [])
