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
}
