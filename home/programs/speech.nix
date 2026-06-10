# Kokoro neural text-to-speech: a `say` command speaking in the af_heart voice.
# Design: docs/superpowers/specs/2026-06-10-kokoro-tts-design.md
{ pkgs, ... }:

let
  python = pkgs.python3;

  # Upstream espeakng-loader exists only to ship a bundled prebuilt
  # libespeak-ng and locate it at runtime — the wrong mechanism on NixOS.
  # This shim exposes the same API backed by nixpkgs' espeak-ng instead.
  espeakng-loader = python.pkgs.buildPythonPackage {
    pname = "espeakng-loader";
    version = "1.0.0-nixpkgs";
    pyproject = true;
    build-system = [ python.pkgs.hatchling ];
    src = pkgs.runCommand "espeakng-loader-src" { } ''
      mkdir -p $out/espeakng_loader
      cat > $out/pyproject.toml <<'EOF'
      [build-system]
      requires = ["hatchling"]
      build-backend = "hatchling.build"

      [project]
      name = "espeakng-loader"
      version = "1.0.0"

      [tool.hatch.build.targets.wheel]
      packages = ["espeakng_loader"]
      EOF
      cat > $out/espeakng_loader/__init__.py <<EOF
      from pathlib import Path

      def get_library_path() -> Path:
          return Path("${pkgs.espeak-ng}/lib/libespeak-ng${pkgs.stdenv.hostPlatform.extensions.sharedLibrary}")

      def get_data_path() -> Path:
          return Path("${pkgs.espeak-ng}/share/espeak-ng-data")

      def make_library_available() -> None:
          pass
      EOF
    '';
  };

  kokoro-onnx = python.pkgs.buildPythonPackage rec {
    pname = "kokoro-onnx";
    version = "0.5.0";
    pyproject = true;
    src = pkgs.fetchPypi {
      pname = "kokoro_onnx";
      inherit version;
      hash = "sha256-W+sV8IXigo7Y1JP3ksB5r4VxA6stzqoeESsXYFh6yWo=";
    };
    build-system = [ python.pkgs.hatchling ];
    # phonemizer-fork only differs from phonemizer in packaging metadata;
    # nixpkgs' phonemizer provides the same `phonemizer` import.
    pythonRemoveDeps = [ "phonemizer-fork" ];
    pythonRelaxDeps = true;
    dependencies = with python.pkgs; [
      colorlog
      numpy
      onnxruntime
      phonemizer
    ] ++ [ espeakng-loader ];
    pythonImportsCheck = [ "kokoro_onnx" ];
  };

  model = pkgs.fetchurl {
    url = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx";
    hash = "sha256-fV347PfUsYeAFaMmhgU/0O6+K8N3I0YIdkzA7zY2psU=";
  };

  voices = pkgs.fetchurl {
    url = "https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin";
    hash = "sha256-vKYQuDCOjZnzLm/kGX5+wBZ5Jk7+0MrJFA/pwp8fv30=";
  };

  pythonEnv = python.withPackages (ps: [ kokoro-onnx ps.soundfile ]);

  sayPy = pkgs.writeText "say.py" ''
    import argparse
    import os
    import subprocess
    import sys
    import tempfile

    import soundfile as sf
    from kokoro_onnx import Kokoro


    def main() -> int:
        parser = argparse.ArgumentParser(
            prog="say", description="Speak text with Kokoro TTS"
        )
        parser.add_argument("--voice", default="af_heart")
        parser.add_argument("--speed", type=float, default=1.0)
        parser.add_argument("-o", "--output", metavar="FILE",
                            help="write wav instead of playing")
        parser.add_argument("text", nargs="*")
        args = parser.parse_args()

        text = " ".join(args.text) if args.text else sys.stdin.read()
        text = text.strip()
        if not text:
            print("say: no text given (pass arguments or pipe stdin)",
                  file=sys.stderr)
            return 1

        kokoro = Kokoro(os.environ["SAY_MODEL"], os.environ["SAY_VOICES"])
        samples, sample_rate = kokoro.create(
            text, voice=args.voice, speed=args.speed, lang="en-us"
        )

        if args.output:
            sf.write(args.output, samples, sample_rate)
            return 0
        with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
            sf.write(tmp.name, samples, sample_rate)
            subprocess.run(["pw-play", tmp.name], check=True)
        return 0


    if __name__ == "__main__":
        sys.exit(main())
  '';

  say = pkgs.writeShellApplication {
    name = "say";
    runtimeInputs = [ pkgs.pipewire ];
    text = ''
      export SAY_MODEL=${model}
      export SAY_VOICES=${voices}
      exec ${pythonEnv}/bin/python ${sayPy} "$@"
    '';
  };
in
{
  home.packages = [ say ];
}
