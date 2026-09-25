{ pkgs }:
let
  wine = pkgs.wineWow64Packages.stable;
  helpers = pkgs.pkgsCross.mingwW64.stdenv.mkDerivation {
    pname = "msp-wine-helpers";
    version = "2026-09-25";
    src = ./.;
    dontConfigure = true;
    buildPhase = ''
      $CC -O2 -Wall -Wextra -Werror -o borderless.exe borderless.c -luser32 -ladvapi32
      $CC -O2 -Wall -Wextra -Werror -shared -o desktop-close.dll desktop-close.c -luser32
      $CC -O2 -Wall -Wextra -Werror -o import-cert.exe charles-wine-cert.c -lcrypt32
    '';
    installPhase = ''
      mkdir -p $out/libexec
      cp borderless.exe desktop-close.dll import-cert.exe $out/libexec/
    '';
  };
in
pkgs.runCommand "msp-wine" {
  nativeBuildInputs = [ pkgs.makeWrapper ];
  passthru = { inherit helpers wine; };
} ''
  mkdir -p $out/bin
  for script in msp-wine-setup msp1-fullscreen; do
    cp ${./.}/$script $out/bin/$script
    chmod +x $out/bin/$script
    patchShebangs $out/bin/$script
    wrapProgram $out/bin/$script \
      --prefix PATH : ${pkgs.lib.makeBinPath [ wine pkgs.winetricks pkgs.python3 pkgs.xdotool pkgs.xprop pkgs.coreutils pkgs.gnugrep ]} \
      --set MSP_WINE_HELPERS ${helpers}/libexec
  done
''
