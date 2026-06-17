{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  libsecret,
  glib,
}:

# Proton Drive CLI ships only as a prebuilt, Bun-compiled standalone binary
# (no nixpkgs package as of 2026-06). It is a glibc-linked ELF with the FHS
# loader (/lib64/ld-linux-x86-64.so.2), so it relies on nix-ld to run (already
# enabled system-wide). At runtime it dlopen()s libsecret-1.so.0 for the OS
# secret store, which in turn needs glib — both supplied via the wrapper below.
stdenv.mkDerivation (finalAttrs: {
  pname = "proton-drive-cli";
  version = "0.4.6";

  src = fetchurl {
    url = "https://proton.me/download/drive/cli/${finalAttrs.version}/linux-x64/proton-drive";
    hash = "sha256-iaVBMaCBHkLqGOxDBz1us0fYD1lO0CJgCbuUEY9M2oY=";
  };

  dontUnpack = true;
  # Bun appends the JS payload after the ELF image; stripping or patchelf would
  # corrupt that trailer (and patching the loader breaks Bun's /proc/self/exe
  # payload lookup), so leave the binary untouched and let nix-ld + the wrapper
  # handle the loader and runtime libraries.
  dontFixup = true;

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 $src $out/libexec/proton-drive
    makeWrapper $out/libexec/proton-drive $out/bin/proton-drive \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libsecret glib ]}
    runHook postInstall
  '';

  meta = {
    description = "Command-line interface for Proton Drive (prebuilt Bun binary)";
    homepage = "https://proton.me/download/drive/cli/index.html";
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    license = lib.licenses.gpl3Plus;
    platforms = [ "x86_64-linux" ];
    mainProgram = "proton-drive";
  };
})
