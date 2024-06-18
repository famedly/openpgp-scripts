# Some parts of this have been copied from https://github.com/drduh/yubikey-guide
# Original License:
# Copyright (c) 2016 drduh
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

{ lib, pkgs, flake, ... }:
let
  viewYubikeyGuide = pkgs.writeShellScriptBin "view-yubikey-guide" ''
    viewer="$(type -P xdg-open || true)"
    if [ -z "$viewer" ]; then
      viewer="${pkgs.glow}/bin/glow -p"
    fi
    exec $viewer "${flake.inputs.yubikeyGuide}/README.md"
  '';
  shortcut = pkgs.makeDesktopItem {
    name = "yubikey-guide";
    icon = "${pkgs.yubikey-manager-qt}/share/icons/hicolor/128x128/apps/ykman.png";
    desktopName = "drduh's YubiKey Guide";
    genericName = "Guide to using YubiKey for GnuPG and SSH";
    comment = "Open the guide in a reader program";
    categories = [ "Documentation" ];
    exec = "${viewYubikeyGuide}/bin/view-yubikey-guide";
  };
  yubikeyGuide = pkgs.symlinkJoin {
    name = "yubikey-guide";
    paths = [ viewYubikeyGuide shortcut ];
  };
in
{
  isoImage = {
    isoName = "fos.iso";

    makeEfiBootable = true;
    makeUsbBootable = true;
  };

  swapDevices = [ ];

  boot = {
    tmp.cleanOnBoot = true;
    kernel.sysctl = { "kernel.unprivileged_bpf_disabled" = 1; };
  };

  services = {
    pcscd.enable = true;
    udev.packages = [ pkgs.yubikey-personalization ];
    # Automatically log in at the virtual consoles.
    getty.autologinUser = "nixos";
    # Comment out to run in a console for a smaller iso and less RAM.
    xserver = {
      enable = true;
      desktopManager.xfce = {
        enable = true;
        enableScreensaver = false;
      };
      displayManager = {
        lightdm.enable = true;
      };
    };
    displayManager.autoLogin = {
      enable = true;
      user = "nixos";
    };
  };

  programs = {
    neovim = {
      enable = true;
      vimAlias = true;
      viAlias = true;
      defaultEditor = true;
    };
    ssh.startAgent = false;
    gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
      pinentryPackage = pkgs.pinentry-curses;
      settings = {
        default-cache-ttl = 60;
        max-cache-ttl = 120;
      };
    };
  };

  # Use less privileged nixos user
  users.users = {
    nixos = {
      isNormalUser = true;
      extraGroups = [ "wheel" "video" ];
      initialHashedPassword = "";
    };
    root.initialHashedPassword = "";
  };

  security = {
    pam.services.lightdm.text = ''
      auth sufficient pam_succeed_if.so user ingroup wheel
    '';
    sudo = {
      enable = true;
      wheelNeedsPassword = false;
    };
  };

  environment.systemPackages = with pkgs; [
    # Tools for backing up keys
    paperkey
    pgpdump
    parted
    cryptsetup

    # Yubico's official tools
    yubikey-manager
    yubikey-manager-qt
    yubikey-personalization
    yubikey-personalization-gui
    yubico-piv-tool
    yubioath-flutter

    # DrDuh's Yubikey Guide (run `view-yubikey-guide` on the terminal
    # to open it in a non-graphical environment).
    yubikeyGuide

    cfssl
    git
    htop
    jq
    okular
    flake.packages.${system}.openpgp-ca # openpgp-ca with famedly patches
    openpgp-card-tools
    pcsctools
    pwgen
    rusty-diceware
    sequoia-sq
    ssss
    tmux

    # Famedly OpenPGP Scripts
    flake.packages.${system}.fos-export
    flake.packages.${system}.fos-mount
    flake.packages.${system}.fos-new
    flake.packages.${system}.fos-partitions
    flake.packages.${system}.fos-sync
    flake.packages.${system}.fos-working-directory
  ];

  nixpkgs.config.allowBroken = true;

  # Disable networking so the system is air-gapped
  # Comment all of these lines out if you'll need internet access
  boot.initrd.network.enable = false;
  networking = {
    resolvconf.enable = false;
    dhcpcd.enable = false;
    dhcpcd.allowInterfaces = [ ];
    interfaces = { };
    firewall.enable = true;
    useDHCP = false;
    useNetworkd = false;
    wireless.enable = false;
    networkmanager.enable = lib.mkForce false;
  };

  # Unset history so it's never stored Set GNUPGHOME to an
  # ephemeral location and configure GPG with the guide

  environment.interactiveShellInit = ''
    unset HISTFILE
    export GNUPGHOME="/run/user/$(id -u)/gnupg"
    if [ ! -d "$GNUPGHOME" ]; then
      echo "Creating \$GNUPGHOME…"
      install --verbose -m=0700 --directory="$GNUPGHOME"
    fi
    echo "\$GNUPGHOME is \"$GNUPGHOME\""
  '';

  system.activationScripts.yubikeyGuide =
    let
      homeDir = "/home/nixos/";
      desktopDir = homeDir + "Desktop/";
      documentsDir = homeDir + "Documents/";
    in
    ''
      mkdir -p ${desktopDir} ${documentsDir}
      chown nixos ${homeDir} ${desktopDir} ${documentsDir}

      cp -R ${flake.inputs.yubikeyGuide}/contrib/* ${homeDir}
      ln -sf ${yubikeyGuide}/share/applications/yubikey-guide.desktop ${desktopDir}
      ln -sfT ${flake.inputs.yubikeyGuide} ${documentsDir}/YubiKey-Guide
    '';

  virtualisation.vmVariant = {
    # VM config for testing, don't handle any sensitive data when running this in a VM only.
    virtualisation = {
      memorySize = 4096;
      cores = 4;
      graphics = true;
    };
  };

  system.stateVersion = "24.05";
}
