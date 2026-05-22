{ ... }:
{
  programs.niri = {
    enable = true;

    # Raw KDL config string — gives full control and matches niri wiki examples exactly
    # Swap to `settings = { ... }` if you prefer type-checked Nix attrs (niri-flake docs)
    config = ''
      // Input
      input {
        keyboard {
          xkb {
            layout "gb"
            // options "caps:escape"
          }
        }
        touchpad {
          tap
          natural-scroll
        }
      }

      // Outputs — run `niri msg outputs` to see your display names
      // output "eDP-1" {
      //   scale 1.0
      //   mode "1920x1080@60.0"
      // }

      layout {
        gaps 8
        center-focused-column "never"
        preset-column-widths {
          proportion 0.33333
          proportion 0.5
          proportion 0.66667
        }
        default-column-width { proportion 0.5; }
        focus-ring {
          width 2
          active-color "#7fc8ff"
          inactive-color "#505050"
        }
        border {
          off
        }
      }

      animations {
        slowdown 1.0
      }

      // Startup
      // DankMaterialShell is started by its niri module (enableSpawn = true in dms.nix)
      spawn-at-startup "swayidle" "-w" "timeout" "300" "swaylock -f" "before-sleep" "swaylock -f"

      prefer-no-csd

      screenshot-path "~/Pictures/Screenshots/screenshot_%Y-%m-%d_%H-%M-%S.png"

      // Keybindings — Mod = Super key
      binds {
        Mod+Return { spawn "foot"; }
        Mod+D { spawn "fuzzel"; }
        Mod+Shift+Q { close-window; }
        Mod+Shift+E { quit; }

        // Focus
        Mod+H { focus-column-left; }
        Mod+L { focus-column-right; }
        Mod+J { focus-window-down; }
        Mod+K { focus-window-up; }
        Mod+Left  { focus-column-left; }
        Mod+Right { focus-column-right; }
        Mod+Down  { focus-window-down; }
        Mod+Up    { focus-window-up; }

        // Move
        Mod+Shift+H { move-column-left; }
        Mod+Shift+L { move-column-right; }
        Mod+Shift+J { move-window-down; }
        Mod+Shift+K { move-window-up; }

        // Workspaces
        Mod+1 { focus-workspace 1; }
        Mod+2 { focus-workspace 2; }
        Mod+3 { focus-workspace 3; }
        Mod+4 { focus-workspace 4; }
        Mod+5 { focus-workspace 5; }
        Mod+Shift+1 { move-window-to-workspace 1; }
        Mod+Shift+2 { move-window-to-workspace 2; }
        Mod+Shift+3 { move-window-to-workspace 3; }
        Mod+Shift+4 { move-window-to-workspace 4; }
        Mod+Shift+5 { move-window-to-workspace 5; }

        // Column sizing
        Mod+R { switch-preset-column-width; }
        Mod+F { maximize-column; }
        Mod+Shift+F { fullscreen-window; }

        // Screenshots
        Print        { screenshot; }
        Shift+Print  { screenshot-window; }
        Ctrl+Print   { screenshot-screen; }

        // Media / brightness
        XF86AudioRaiseVolume  { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%+"; }
        XF86AudioLowerVolume  { spawn "wpctl" "set-volume" "@DEFAULT_AUDIO_SINK@" "5%-"; }
        XF86AudioMute         { spawn "wpctl" "set-mute" "@DEFAULT_AUDIO_SINK@" "toggle"; }
        XF86MonBrightnessUp   { spawn "brightnessctl" "set" "10%+"; }
        XF86MonBrightnessDown { spawn "brightnessctl" "set" "10%-"; }
      }
    '';
  };
}
