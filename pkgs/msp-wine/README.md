# MovieStarPlanet on NixOS / niri

Adapted from the personal `msp-wine-setup.zip` bundle dated 2026-09-25.
The three C helper sources come from that bundle. The borderless helper now
loads its wallpaper from `C:\msp-wine\black.bmp` instead of a hard-coded home.
Nix cross-compiles the helpers with MinGW; Wine development headers and a
compiler are not needed at runtime.

`home/programs/msp-wine.nix` installs the package, application launcher, niri
window rule and Charles launcher fix on Framework. Rebuild the configuration
to persist these in the normal user environment.

Download the Windows installer from https://moviestarplanet.com/download/ then:

```sh
msp-wine-setup install ~/Downloads/MovieStarPlanetSetup2.0.13.exe
msp1-fullscreen
```

The installer and game are proprietary, downloaded separately, and kept out of
the Nix store. The dedicated prefix is `~/.local/share/msp-wine/prefix`.
Installation uses Winetricks for `mfc42` and `dotnet48`, then selects Windows 10.
If runtime installation fails, rerun the install command; an existing installed
game is never overwritten by this command. Use `msp-wine-setup configure` to
reapply registry settings and regenerate the wallpaper.

The fixed window size is 2560×1396 for 2560×1440 external displays at scale 1,
leaving 44 pixels for DMS. The game is centered at 2371×1396. For other screen
sizes, change both the launcher dimensions and Home Manager's niri rule.
The laptop's internal display requires different dimensions.

Charles proxying is opt-in and applies only to this Wine prefix:

```sh
msp-wine-setup proxy on   # Charles must listen on 127.0.0.1:8888
msp-wine-setup trust /path/to/charles.der
msp-wine-setup proxy off
```

Export the public DER certificate from Charles and enable SSL Proxying for the
desired hosts there. No certificate or private key is bundled. Linux's trust
store and global proxy settings are not changed.

The configured Charles SSL host patterns are `moviestarplanet.*`,
`*.moviestarplanet.*`, `mspcdns.com`, and `*.mspcdns.com`, on port 443.
These mutable settings live in `~/.charles.config`; the local CA stays in
`~/.charles/ca`. To export the public certificate from the command line:

```sh
charles ssl export ~/.local/share/msp-wine/charles.crt
~/.local/bin/msp-wine-setup trust ~/.local/share/msp-wine/charles.crt
```

Start Charles before MSP while proxying is enabled. Restart MSP after changing
proxy settings. To play without Charles, run
`~/.local/bin/msp-wine-setup proxy off` and restart MSP.
The Charles desktop entry sets Java's font hints explicitly to prevent its
startup UI error on niri, in addition to the non-reparenting window-manager fix.

Registry backups from configuration are under `~/.local/state/msp-wine-setup`.
Close the game before reconfiguring. The standard niri close-window action
forwards a close request to the game through the bundled desktop-close DLL.
