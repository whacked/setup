# sikulix
# with import <nixpkgs> {};

{ lib, stdenv, fetchurl,
  opencv3, ant, adoptopenjdk-bin,
  gcc-unwrapped, pythonPackages,
  glibcLocales
}:

let
  opencv3_with_java = opencv3.overrideAttrs(oldAttrs: rec {
    buildInputs = oldAttrs.buildInputs ++ [
      ant
      adoptopenjdk-bin
    ] ++ lib.optional true pythonPackages.python;
    propagatedBuildInputs = lib.optional true pythonPackages.numpy;
    cmakeFlags = oldAttrs.cmakeFlags ++ [
      "-DBUILD_opencv_java=ON"
      "-DBUILD_JAVA=ON"
      "-DBUILD_opencv_java_bindings_gen=ON"
      "-DWITH_JAVA=ON"
    ];
  });
in stdenv.mkDerivation rec {
  pname = "sikulix";
  version = "2.0.4";

  src = fetchurl {
    url="https://launchpad.net/sikuli/sikulix/${version}/+download/sikulixide-${version}.jar";
    sha256 = "0pq0d58h4svkgnw3h5qv27bzmap2cgx0pkhmq824nq4rdj9ivphi";
  };
  # TODO: remove this
  # it works ok with nix-provided jython (v2.7.2b3)
  # but regardless of which version you use it MUST be symlinked in
  # $HOME/.Sikulix/Extensions/jython.jar --> original_path
  jython_jar = fetchurl {
    url="https://repo1.maven.org/maven2/org/python/jython-standalone/2.7.1/jython-standalone-2.7.1.jar";
    sha256 = "0jwc4ly75cna78blnisv4q8nfcn5s0g4wk7jf4d16j0rfcd0shf4";
  };
  dontUnpack = true;

  buildInputs = [
    opencv3_with_java
    adoptopenjdk-bin
    glibcLocales
    gcc-unwrapped
  ];
  installPhase = ''
    mkdir -p $out/bin/
    mv ${src} $out/bin/sikulix.jar
    # this step is most likely unnecessary
    mv $jython_jar $out/bin/jython.jar

    ln -s ${opencv3_with_java.out}/share/OpenCV/java/libopencv_java348.so $out/bin/libopencv_java.so

    cat > $out/bin/sikulix <<EOF
    export LD_LIBRARY_PATH=${gcc-unwrapped.lib}/lib
    # this step does not affect runnability (.Sikulix is more important)
    export CLASSPATH=$out/bin/jython.jar
    ${adoptopenjdk-bin}/bin/java -jar $out/bin/sikulix.jar \$@
    EOF
    chmod +x $out/bin/sikulix
  '';
}

