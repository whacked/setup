with (import <nixpkgs> {});
 
 stdenv.mkDerivation {
   name = "emacs-pdf-tools";
 
   buildInputs = [
       emacs
       emacsPackagesNg.melpaPackages.pdf-tools
   ];
   shellHook = ''
       epdfinfo_path=$(find ${emacsPackagesNg.melpaPackages.pdf-tools} -name epdfinfo)
       cp $epdfinfo_path $HOME/.emacs.d/elpa/pdf-tools*/
   '';
 }
