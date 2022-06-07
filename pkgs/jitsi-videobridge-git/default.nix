{ stdenv, fetchzip, fetchMavenDeps, unzip, jre, maven, nixosTests
, version ? "git"
, srcUrl ? "https://github.com/jitsi/jitsi-videobridge/archive/389b69ff9c7a9ae73d1375584c3307ea11ced152.tar.gz"
, sha256 ? "1ggcbrh1vg3j2d4514rifkza7i2vr44dvdnvmzbsm3r586b97f6q"
, dependencies-sha256 ? "1kdpny5zg7vw0ns6z21bamzkcmw60jjni24zxxydlsgid7afp6na"
}:

let
  src = fetchzip {
    url = srcUrl;
    inherit sha256;
  };
  pname = "jitsi-videobridge";

  deps = fetchMavenDeps {
    inherit pname version src;
    sha256 = dependencies-sha256;
  };
in
stdenv.mkDerivation {
  inherit pname version src;

  nativeBuildInputs = [ maven unzip ];
  buildInputs = [ jre ];

  buildPhase = ''
    cp -dpR "${deps}/.m2" ./
    chmod -R +w .m2
    mvn package --offline -Dmaven.repo.local="$(pwd)/.m2"
  '';

  installPhase = ''
    mkdir -p $out/{bin,share,etc/jitsi/videobridge}

    unzip target/jitsi-videobridge-*-archive.zip -d $out/share
    mv $out/share/jitsi-videobridge-* $out/share/jitsi-videobridge

    substituteInPlace $out/share/jitsi-videobridge/jvb.sh \
      --replace "exec java" "exec ${jre}/bin/java"

    mv $out/share/jitsi-videobridge/lib/logging.properties $out/etc/jitsi/videobridge/
    cp ${./logging.properties-journal} $out/etc/jitsi/videobridge/logging.properties-journal

    rm $out/share/jitsi-videobridge/jvb.bat
    ln -s $out/share/jitsi-videobridge/jvb.sh $out/bin/jitsi-videobridge
  '';

  passthru.tests = {
    inherit (nixosTests) jitsi-meet;
  };
}
