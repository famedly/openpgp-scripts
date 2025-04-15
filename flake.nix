{
  description = "famedly-openpgp-scripts (short fos)";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixpkgs-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
    yubikeyGuide = {
      url = "github:drduh/YubiKey-Guide";
      flake = false;
    };
  };

  outputs = inputs@{ self, nixpkgs, flake-parts, ... }:

    flake-parts.lib.mkFlake { inherit inputs; } {

      imports = [ ];

      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];

      perSystem = { config, pkgs, ... }: {
        formatter = pkgs.nixpkgs-fmt;
        packages = {
          fos-export = pkgs.writeShellScriptBin "fos-export" (builtins.readFile ./fos-export);
          fos-flash = pkgs.writeShellScriptBin "fos-flash" (builtins.readFile ./fos-flash);
          fos-generate = pkgs.writeShellScriptBin "fos-generate" (builtins.readFile ./fos-generate);
          fos-mount = pkgs.writeShellScriptBin "fos-mount" (builtins.readFile ./fos-mount);
          fos-partitions = pkgs.writeShellScriptBin "fos-partitions" (builtins.readFile ./fos-partitions);
          fos-sync = pkgs.writeShellScriptBin "fos-sync" (builtins.readFile ./fos-sync);
          fos-working-directory = pkgs.writeShellScriptBin "fos-working-directory" (builtins.readFile ./fos-working-directory);
          openpgp-ca = pkgs.openpgp-ca.overrideAttrs (prevAttrs: rec {
            version = "${prevAttrs.version}-famedly";
            src = pkgs.fetchFromGitHub {
              owner = "famedly";
              repo = "openpgp-ca";
              rev = "expose-more-functionality";
              hash = "sha256-+dAwGq3/86A1oLGdjvRHLmS+SiZrv/DqTi+fTRG8uZQ=";
            };
            cargoDeps = prevAttrs.cargoDeps.overrideAttrs (pkgs.lib.const {
              name = "${prevAttrs.pname}-vendor.tar.gz";
              inherit src;
              outputHash = "sha256-hmgWa4pas3qngs6MNPzk3fPG5+jFRph0lGZvtUF4/tA=";
            });
          });
        };
      };

      flake =
        let
          mkSystem = system:
            nixpkgs.lib.nixosSystem {
              inherit system;
              modules = [
                "${nixpkgs}/nixos/modules/profiles/all-hardware.nix"
                "${nixpkgs}/nixos/modules/installer/cd-dvd/iso-image.nix"
                ./iso.nix
              ];
              specialArgs = {
                inherit inputs;
                flake = self;
              };

            };
        in
        {
          nixosConfigurations.fos-live = mkSystem "x86_64-linux";
          nixosConfigurations.fos-live-aarch64 = mkSystem "aarch64-linux";
        };
    };
}
