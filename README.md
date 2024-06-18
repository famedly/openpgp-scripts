# famedly-openpgp-scripts (short `fos`)

These are scripts we use to provision hardware keys with OpenPGP certificates for our team members.

## Dependencies
- oca (https://openpgp-ca.org/, patches from https://github.com/famedly/openpgp-ca/tree/expose-more-functionality)
- oct>=0.10.0 (https://codeberg.org/openpgp-card/openpgp-card-tools)
- sq>=0.33.0 (https://sequoia-pgp.org/projects/#sq)
- rusty-diceware (https://gitlab.com/yuvallanger/rusty-diceware/)
- jq
- bash
- coreutils

## Building an ISO

You can use the Nix Flake in this repo to build an ISO which has all of the scripts, dependencies for working with PGP and YubiKeys, as well as [DrDuh's Yubikey Guide](https://github.com/drduh/YubiKey-Guide/) available, and all networking disabled.

All you need is to have [Nix](https://nixos.org/download/) installed and either enable flakes in your nix config, or add `--experimental-features "nix-command flakes"` to all nix commands.

Then you can run the following command to build the ISO:
```
nix build .#nixosConfigurations.fos-live.config.system.build.isoImage
```
The resulting ISO can be found in `./result/iso/fos.iso`

## Building a VM

For testing purposes, you can also build a VM with the configuration:

On NixOS:
```
nixos-rebuild build-vm --flake .#fos-live
```

On Non-NixOS:
```
nix run 'nixpkgs#nixos-rebuild' -- build-vm --flake .#fos-live
```

The VM can than be run from `./result/bin/run-nixos-vm`
