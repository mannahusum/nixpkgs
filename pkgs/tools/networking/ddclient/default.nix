{ lib, fetchurl, perlPackages, iproute2, perl }:

perlPackages.buildPerlPackage rec {
  pname = "ddclient";
  version = "3.9.1";

  src = fetchurl {
    url = "mirror://sourceforge/ddclient/${pname}-${version}.tar.gz";
    sha256 = "0w14qnn72j333i3j7flxkw6bzcg4n31d8jfnvhmwa7s9rharx5p4";
  };

  # perl packages by default get devdoc which isn't present
  outputs = [ "out" ];

  buildInputs = with perlPackages; [ IOSocketSSL DigestSHA1 DataValidateIP JSONPP ];

  # Use iproute2 instead of ifconfig
  preConfigure = ''
    touch Makefile.PL
    substituteInPlace ddclient \
      --replace 'in the output of ifconfig' 'in the output of ip addr show' \
      --replace 'ifconfig -a' '${iproute2}/sbin/ip addr show' \
      --replace 'ifconfig $arg' '${iproute2}/sbin/ip addr show $arg' \
      --replace '/usr/bin/perl' '${perl}/bin/perl' # Until we get the patchShebangs fixed (issue #55786) we need to patch this manually
  '';

  installPhase = ''
    runHook preInstall

    install -Dm755 ddclient $out/bin/ddclient
    install -Dm644 -t $out/share/doc/ddclient COP* ChangeLog README.* RELEASENOTE

    runHook postInstall
  '';

  # there are no tests distributed with ddclient
  doCheck = false;

  meta = with lib; {
    description = "Client for updating dynamic DNS service entries";
    homepage    = "https://sourceforge.net/p/ddclient/wiki/Home/";
    license     = licenses.gpl2Plus;
    # Mostly since `iproute` is Linux only.
    platforms   = platforms.linux;
  };
}
