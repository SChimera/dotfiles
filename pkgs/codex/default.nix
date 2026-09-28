{ codex, fetchurl, bubblewrap }:
# codex-nix 0.158.0 packages individual binaries, but daemon startup requires
# the complete release layout. Remove this override once upstream bundles it.
assert codex.version == "0.158.0";
codex.overrideAttrs (old: {
  buildPhase = ''
    runHook preBuild
    mkdir -p build
    tar -xzf ${fetchurl {
      url = "https://github.com/openai/codex/releases/download/rust-v${old.version}/codex-package-x86_64-unknown-linux-musl.tar.gz";
      hash = "sha256-szzUJsmsq5s0xakyALpP6DyOYUwYzl71KyvzZAi44Yw=";
    }} -C build
    runHook postBuild
  '';
  installPhase = ''
    runHook preInstall
    mkdir -p $out/bin $out/libexec/codex-package
    cp -a build/. $out/libexec/codex-package/
    makeWrapper "$out/libexec/codex-package/bin/codex" "$out/bin/codex" \
      --set DISABLE_AUTOUPDATER 1 \
      --prefix PATH : "${bubblewrap}/bin"
    ln -s ../libexec/codex-package/bin/codex-code-mode-host $out/bin/codex-code-mode-host
    runHook postInstall
  '';
})
