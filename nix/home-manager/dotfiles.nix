{ config, lib, ... }:

let
  repoRoot = ../..;

  mkTreeLinks = {
    targetPrefix,
    sourceDir,
    executableFor ? (_: false),
  }:
    let
      entries = builtins.readDir sourceDir;
      mkFromName = name:
        let
          kind = entries.${name};
          relPath =
            if targetPrefix == "" then
              name
            else
              "${targetPrefix}/${name}";
          srcPath = sourceDir + "/${name}";
        in
        if kind == "directory" then
          mkTreeLinks {
            targetPrefix = relPath;
            sourceDir = srcPath;
            executableFor = executableFor;
          }
        else if kind == "regular" || kind == "symlink" then
          {
            "${relPath}" =
              {
                source = srcPath;
              }
              // lib.optionalAttrs (executableFor relPath) {
                executable = true;
              };
          }
        else
          { };
    in
    lib.foldl' lib.recursiveUpdate { } (map mkFromName (builtins.attrNames entries));
in
{
  options.dotfiles.enable = lib.mkEnableOption "Manage these dotfiles with Home Manager";

  config = lib.mkIf config.dotfiles.enable {
    home.file = {
      ".bashrc".source = "${repoRoot}/.bashrc";
      ".bash_aliases".source = "${repoRoot}/.bash_aliases";
      ".gdbinit".source = "${repoRoot}/.gdbinit";

      ".config/starship.toml".source = "${repoRoot}/starship.toml";
      ".local/bin/layout_detec.sh" = {
        source = "${repoRoot}/scripts/layout_detec.sh";
        executable = true;
      };

      "Pictures/wallpapers" = {
        source = "${repoRoot}/wallpapers";
        recursive = true;
      };
    }
    // (mkTreeLinks {
      targetPrefix = ".xmonad";
      sourceDir = repoRoot + "/.xmonad";
      executableFor = relPath:
        lib.hasPrefix ".xmonad/scripts/" relPath && lib.hasSuffix ".sh" relPath;
    });

    xdg.configFile = {
      "alacritty/alacritty.toml".source = "${repoRoot}/alacritty/alacritty.toml";
      "awesome" = {
        source = "${repoRoot}/awesome";
        recursive = true;
      };
      "picom/picom.conf".source = "${repoRoot}/picom/picom.conf";
      "ranger" = {
        source = "${repoRoot}/ranger";
        recursive = true;
      };
      "starship/starship.toml".source = "${repoRoot}/starship/starship.toml";
      "yazi/yazi.toml".source = "${repoRoot}/yazi/yazi.toml";
      "mpv/mpv.conf".source = "${repoRoot}/mpv.conf";
    }
    // (mkTreeLinks {
      targetPrefix = "xmonad";
      sourceDir = repoRoot + "/xmonad";
      executableFor = relPath:
        lib.hasPrefix "xmonad/scripts/" relPath && lib.hasSuffix ".sh" relPath;
    });
  };
}
