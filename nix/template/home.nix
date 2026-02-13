{ config, pkgs, ... }:

{
  imports = [
    # Replace this path with your checkout path if needed:
    /path/to/dotfiles/nix/home-manager/dotfiles.nix
  ];

  dotfiles.enable = true;

  # Standard Home Manager settings
  home.username = "your-user";
  home.homeDirectory = "/home/your-user";
  home.stateVersion = "24.11";

  programs.home-manager.enable = true;
}
