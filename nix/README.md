# Nix variants for your dotfiles

This directory contains the Nix/Home Manager variant of your existing configuration.
The original files are kept as-is; the Nix module only links them into your home directory.

## What was added

- `flake.nix`: exposes the Home Manager module.
- `nix/home-manager/dotfiles.nix`: module that maps your current dotfiles into `home.file` and `xdg.configFile`.
- `nix/template/home.nix`: starting point for a NixOS/Home Manager setup.

## XMonad coverage

Both XMonad layouts are fully included:

- `~/.xmonad/**` (including `xmonad.hs`, `xmobar`, scripts, wallpapers, and library files)
- `~/.config/xmonad/**` (including `.xmobarrc` and scripts)

The module creates links for every file in those trees and keeps `.sh` files in `scripts/` executable.

## Quick usage

1. Clone this repository on your NixOS machine.
2. Import `nix/home-manager/dotfiles.nix` in your Home Manager config.
3. Set `dotfiles.enable = true;`.

After that, your original config files remain the source of truth.
