{ config, lib, pkgs, pkgs-unstable, ... }:
{
  home.packages = [ pkgs-unstable.vesktop ];

  # DMS generates and refreshes themes/dank-discord.css automatically. Merge
  # its enabled state into the writable settings so UI preferences survive.
  home.activation.enableVesktopTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    run ${pkgs.python3}/bin/python - ${lib.escapeShellArg "${config.xdg.configHome}/vesktop/settings/settings.json"} ${./vesktop/backgrounds.css} <<'PYTHON'
    import json
    import pathlib
    import sys

    path = pathlib.Path(sys.argv[1])
    settings = json.loads(path.read_text()) if path.exists() else {}
    original = json.dumps(settings)
    themes = settings.setdefault("enabledThemes", [])
    if "dank-discord.css" not in themes:
        themes.append("dank-discord.css")
    settings["useQuickCss"] = True
    if json.dumps(settings) != original:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(json.dumps(settings, indent=4) + "\n")

    # Keep user QuickCSS outside this managed block. Vencord watches this file
    # and applies edits immediately, including after Home Manager activation.
    css_path = path.with_name("quickCss.css")
    css = css_path.read_text() if css_path.exists() else ""
    start = "/* BEGIN dotfiles DMS backgrounds */"
    end = "/* END dotfiles DMS backgrounds */"
    import re
    css = re.sub(re.escape(start) + r".*?" + re.escape(end) + r"\n?", "", css, flags=re.S)
    overrides = pathlib.Path(sys.argv[2]).read_text()
    css_path.parent.mkdir(parents=True, exist_ok=True)
    css_path.write_text(css.rstrip() + "\n" + start + "\n" + overrides + end + "\n")
    PYTHON
  '';
}
