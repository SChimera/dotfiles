# Kokoro TTS — declarative `say` command

**Date**: 2026-06-10
**Status**: approved

## Goal

Replace the experimental Kokoro venv in `~/.local/share/kokoro` with a fully
declarative home-manager module providing a `say` command that speaks text in
the Kokoro `af_heart` voice. Primary use case: Claude Code reading replies
aloud; secondary: any manual/scripted text-to-speech.

## Decisions

- **In-repo module**, not a separate flake (single consumer; extract later if
  ever published).
- **`say` CLI only** — no speech-dispatcher integration for now. Can be added
  later without rework.
- **Host scope**: haven only (`home/hosts/haven.nix`), next to `gaming.nix`.

## Architecture

One new file, `home/programs/speech.nix`, containing:

1. **`espeakng-loader` shim** — a tiny `buildPythonPackage` whose
   `get_library_path()` / `get_data_path()` return nixpkgs `espeak-ng` paths.
   Upstream `espeakng-loader` only exists to ship a bundled binary lib, which
   is the wrong mechanism on NixOS.
2. **`kokoro-onnx`** — `buildPythonPackage` from PyPI, depending on nixpkgs
   `onnxruntime`, `numpy`, `colorlog`, `phonemizer` (stands in for
   `phonemizer-fork`; same `phonemizer` import, fork differs only in
   packaging), and the shim above.
3. **Model + voices** — `fetchurl` from the kokoro-onnx GitHub release
   `model-files-v1.0` (`kokoro-v1.0.onnx` ~310 MB, `voices-v1.0.bin` ~27 MB),
   pinned by sha256. Lives in the nix store: GC-safe, deduped.
4. **`say`** — `writeShellApplication` wrapping a small Python entry point.
   - Input: arguments (`say hello world`) or stdin (`echo hi | say`).
   - Flags: `--voice` (default `af_heart`), `--speed` (default 1.0),
     `-o FILE` to write a wav instead of playing.
   - Playback: `pw-play` (PipeWire).

`home/hosts/haven.nix` imports the module; `home.packages` gets `say`.

## Error handling

- Empty input: print usage to stderr, exit 1, no model load.
- Synthesis/python failure surfaces its traceback (no swallowing).

## Verification

1. `nixos-rebuild build` of the haven toplevel succeeds.
2. After `nixswitch`: `echo "test" | say` produces audio; `say --voice af_sarah "hi"`
   works; `say -o /tmp/x.wav "hi"` writes a file and does not play.

## Cleanup (post-verification)

Delete `~/.local/share/kokoro` (venv experiment, 423 MB, includes the
`python-env` GC root).
