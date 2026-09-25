# Slack wallpaper theme

`home/programs/slack.nix` installs a patched Slack package and a DMS/Matugen
CSS template. DMS generates `~/.cache/matugen/slack.css` on wallpaper and
appearance changes. A Matugen post-hook signals the registered patched Slack process, which
replaces its stylesheet without reloading the app. The registration includes
the process start time and executable path to guard against PID reuse. The template follows Matugen's active
light/dark mode.

The package prepends a local main-process hook to Slack's existing entry point.
It uses Electron's `insertCSS` API; no remote debugging port, credentials,
network requests, or renderer Node integration are needed. Native modules stay
unpacked. A Slack restart is required after installing or updating the patch.
The user desktop entry launches the patched package even before a full NixOS
rebuild updates the system-managed user package profile.

Slack's internal CSS variables and selectors can change between releases. If
some areas stop following the palette, update `theme.css`. Remove the module
import and restore the stock `slack` package to undo the integration, then
activate Home Manager/rebuild and restart Slack.

Checks:

```sh
node --test pkgs/slack-matugen/inject.test.cjs
nix build --no-link .#nixosConfigurations.framework.config.home-manager.users.seb.home.activationPackage
```

The initial implementation was also checked with a local Electron fixture for
real CSS insertion, live dark/light changes, navigation, and stylesheet removal.
`cssOrigin: 'author'` is intentional: user-origin removal did not work in the
Electron 43 fixture. Styles use `!important` to override Slack's colors.
