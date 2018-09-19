with import <nixpkgs> {}; # bring all Nixpkgs into scope

stdenv.mkDerivation rec {
  name = "electron-v3.0.0";
  src = fetchurl {
    # if you have the file saved locally, use e.g. this
    # url = "file:///tmp/electron-v3.0.0-linux-x64.zip";
    url = "https://github.com/electron/electron/releases/download/v3.0.0/electron-v3.0.0-linux-x64.zip";
    sha256 = "0sdvnksk6z9xyri4g3z6414fkj4lvrq495g98nz14vypy6ab32dl";
  };

  buildInputs = [ unzip xorg.libXScrnSaver makeWrapper nss nspr ];

  unpackPhase = ''
  unzip $src
  '';
  
  installPhase = ''
  mkdir -p $out/bin
  mv ./* $out/bin/
  wrapProgram $out/bin/electron \
    --prefix LD_PRELOAD : ${lib.concatMapStrings (x: ":" + x) [
        "${stdenv.lib.makeLibraryPath [ xorg.libXScrnSaver ]}/libXss.so.1"
        "${stdenv.lib.makeLibraryPath [ nss ]}/libnss3.so"
        "${stdenv.lib.makeLibraryPath [ nss ]}/libnssutil3.so"
        "${stdenv.lib.makeLibraryPath [ nss ]}/libsmime3.so"
        "${stdenv.lib.makeLibraryPath [ nspr ]}/libnspr4.so"
    ]}
  '';

  shellHook = ''
  which electron
  ls -l 
  '';

  meta = {
    homepage = https://github.com/electron/electron;
  };
}
