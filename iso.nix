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
    icon = "${pkgs.yubioath-flutter}/share/pixmaps/com.yubico.yubioath.png";
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
    desktopManager.plasma6.enable = true;
    greetd = {
      enable = true;
      settings = {
        initial_session = {
          command = "startplasma-wayland";
          user = "nixos";
        };
        default_session = {
          command = "${pkgs.greetd.greetd}/bin/agreety --cmd startplasma-wayland";
          user = "greeter";
        };
      };
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

  time.timeZone = "Europe/Berlin";

  security = {
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
    yubikey-personalization
    yubico-piv-tool
    yubioath-flutter

    # DrDuh's Yubikey Guide (run `view-yubikey-guide` on the terminal
    # to open it in a non-graphical environment).
    yubikeyGuide

    cfssl
    flake.packages.${system}.openpgp-ca # openpgp-ca with famedly patches
    git
    htop
    jq
    kdePackages.falkon
    kdePackages.okular
    nano
    neovim
    openpgp-card-tools
    pcsctools
    pwgen
    rusty-diceware
    sequoia-sq
    ssss
    tmux
    wayland-utils
    wl-clipboard

    # Famedly OpenPGP Scripts
    flake.packages.${system}.fos-export
    flake.packages.${system}.fos-flash
    flake.packages.${system}.fos-generate
    flake.packages.${system}.fos-mount
    flake.packages.${system}.fos-partitions
    flake.packages.${system}.fos-renew
    flake.packages.${system}.fos-rotate-passwords
    flake.packages.${system}.fos-sync
    flake.packages.${system}.fos-working-directory
  ];

  environment.plasma6.excludePackages = with pkgs.kdePackages; [
    elisa
    kdepim-runtime
    krdp
    oxygen
    plasma-browser-integration
  ];

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
      qemu.options = [
        "-vga none"
        "-device virtio-gpu"
        "-usbdevice tablet"
      ];
    };
  };

  system.stateVersion = "24.05";
}
