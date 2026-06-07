{ lib, ... }:
# Declarative default-application handlers, written to ~/.config/mimeapps.list.
#
# Migrated from a previously-imperative mimeapps.list (set via `xdg-mime` /
# app "set as default" actions) so the defaults are now reproducible. Once
# `xdg.mimeApps.enable` is on, home-manager OWNS this file as a read-only
# symlink — change defaults here, not via GUI/`xdg-mime` (those will fail to
# write). The old real file must be removed once so HM can take over.
let
  firefox = "firefox.desktop";
  swayimg = "swayimg.desktop";

  # Mirror swayimg.desktop's own MimeType= list so the default matches what
  # the viewer actually claims to handle. gwenview is also installed and stays
  # available via "Open With" (it declares these types in its own .desktop).
  imageMimes = [
    "image/avif"
    "image/bmp"
    "image/gif"
    "image/heif"
    "image/jpeg"
    "image/jpg"
    "image/jxl"
    "image/pbm"
    "image/pjpeg"
    "image/png"
    "image/svg+xml"
    "image/tiff"
    "image/webp"
    "image/x-bmp"
    "image/x-exr"
    "image/x-png"
    "image/x-portable-anymap"
    "image/x-portable-bitmap"
    "image/x-portable-graymap"
    "image/x-portable-pixmap"
    "image/x-targa"
    "image/x-tga"
  ];
in
{
  xdg.mimeApps = {
    enable = true;
    defaultApplications = {
      # Web / browser
      "x-scheme-handler/http" = firefox;
      "x-scheme-handler/https" = firefox;
      "x-scheme-handler/chrome" = firefox;
      "text/html" = firefox;
      "application/xhtml+xml" = firefox;
      "application/x-extension-htm" = firefox;
      "application/x-extension-html" = firefox;
      "application/x-extension-shtml" = firefox;
      "application/x-extension-xhtml" = firefox;
      "application/x-extension-xht" = firefox;

      # Application URL schemes
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/claude-cli" = "claude-code-url-handler.desktop";

      # File manager
      "inode/directory" = "org.kde.dolphin.desktop";
    }
    # Images -> swayimg
    // lib.genAttrs imageMimes (_: swayimg);
  };

  # Upstream swayimg.desktop ships NoDisplay=true (it's CLI-first). KDE/Dolphin
  # refuses to launch a NoDisplay app as a handler, so double-clicking an image
  # does nothing (gio/xdg-open don't care, which is why the default "looks" set).
  # Ship a user-level override with the same desktop id (higher XDG precedence)
  # and NoDisplay cleared so Dolphin will actually launch it. Written via
  # home.file rather than xdg.desktopEntries because the latter only emits when
  # xdg.enable = true (off here), and we don't want full XDG management.
  home.file.".local/share/applications/swayimg.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Swayimg
    GenericName=Image viewer
    Comment=Image viewer for Sway/Wayland
    Icon=swayimg
    Exec=env LC_NUMERIC=C swayimg %F
    Terminal=false
    Categories=Graphics;Viewer
    StartupNotify=false
    MimeType=${lib.concatStringsSep ";" imageMimes};
    NoDisplay=false
  '';

  # --- Make KDE/Dolphin able to LAUNCH file handlers under niri ----------------
  # In a bare niri session (no Plasma), KDE can't locate its applications menu,
  # so KIO can't resolve/launch ANY handler — double-clicking a file in Dolphin
  # silently fails with "The name is not activatable". Fix (no kded6, which would
  # conflict with the DMS/quickshell tray):
  #   1. XDG_MENU_PREFIX=plasma- in the session env, via home.sessionVariables
  #      (hm-session-vars.sh, sourced at login). Verified this is the channel that
  #      actually reaches the niri session here — it's how XCURSOR_THEME gets in.
  #      environment.d only reaches the systemd --user manager, NOT niri-spawned
  #      apps like Dolphin, so it does not work for this.
  #   2. A plasma-applications.menu for KDE to read (minimal "include all").
  # KService rebuilds its sycoca cache on next app launch. Takes effect only after
  # a full re-login (session env is established at login), not just `nixswitch`.
  # Ref: archwiki "Dolphin#Dolphin_cannot_find_applications_(when_running_under_another_window_manager)"
  home.sessionVariables.XDG_MENU_PREFIX = "plasma-";

  home.file.".config/menus/plasma-applications.menu".text = ''
    <!DOCTYPE Menu PUBLIC "-//freedesktop//DTD Menu 1.0//EN" "http://www.freedesktop.org/standards/menu-spec/menu-1.0.dtd">
    <Menu>
      <Name>Applications</Name>
      <DefaultAppDirs/>
      <DefaultDirectoryDirs/>
      <Include><All/></Include>
    </Menu>
  '';

  # swayimg's default window background is transparent (#00000000), so the area
  # around a non-filling image shows the wallpaper / an odd tint. Give it a solid
  # dark background. (LC_NUMERIC=C in the .desktop Exec above also stops swayimg's
  # locale-sensitive float parser choking on dotted values under en-DK.)
  home.file.".config/swayimg/config".text = ''
    [viewer]
    window = #1e1e1eff

    [slideshow]
    window = #1e1e1eff

    [gallery]
    window = #1e1e1eff
    background = #1e1e1eff
  '';
}
