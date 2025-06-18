{ config, pkgs, ... }:

{
  # https://nix-community.github.io/home-manager/options.xhtml
  home.username = "nixos";
  home.homeDirectory = "/home/nixos";
  home.stateVersion = "25.05";
  programs.home-manager.enable = true;

  # https://nix-community.github.io/plasma-manager/options.xhtml
  programs.plasma = {
    enable = true;
    workspace = {
      lookAndFeel = "org.kde.breezedark.desktop";
    };
    panels = [
      {
        location = "bottom";
        floating = true;
        widgets = [
          {
            kicker = {
              behavior = {
                sortAlphabetically = true;
              };
              settings = {
                icon = "nix-snowflake";
              };
            };
          }
          {
            iconTasks = {
              launchers = [
                "applications:org.kde.dolphin.desktop"
                "applications:org.kde.konsole.desktop"
                "applications:org.kde.kate.desktop"
              ];
            };
          }
          "org.kde.plasma.marginsseparator"
          {
            systemTray.items = {
              hidden = [
                "org.kde.plasma.networkmanagement"
                "org.kde.plasma.volume"
              ];
            };
          }
          {
            digitalClock = {
              calendar.firstDayOfWeek = "monday";
              time.format = "24h";
            };
          }
        ];
      }
    ];
    input.keyboard.layouts = [
      {
        layout = "us";
      }
      {
        layout = "gb";
      }
      {
        layout = "de";
        variant = "nodeadkeys";
      }
    ];
    kscreenlocker = {
      lockOnResume = false;
      passwordRequired  = false;
    };
    powerdevil = {
      AC.autoSuspend.action = "nothing";
      battery.autoSuspend = {
        action = "sleep";
        idleTimeout = 1800;
      };
    };
  };
}
