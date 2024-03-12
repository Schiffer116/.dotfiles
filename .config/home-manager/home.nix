{ config, pkgs, ... }:

{
  home.username = "schiffer";
  home.homeDirectory = "/home/schiffer";

  home.stateVersion = "23.11"; # Please read the comment before changing.

  home.packages = [
  ];

  home.file = {
    # ".screenrc".source = dotfiles/screenrc;
    # ".config/hypr".source = ./hypr;
    # ".config/nvim".source = ./nvim;
    # ".config/starship.toml".source = ./starship.toml;
    # ".config/home-manager".source = ./home-manager;
    # ".config/nvim".source = ./nvim;
    # ".config/nvim".source = ./nvim;
  };

  # home.sessionVariables = {
  # };

  programs.git = {
    enable = true;
    userName = "Schiffer116";
    userEmail = "khanhpg5@gmail.com";
  };

  gtk = {
    enable = true;
    cursorTheme = {
        name = "Bibata-Modern-Ice";
        package = pkgs.bibata-cursors;
    };
    theme = {
      name = "Catppuccin-Mocha-Standard-Blue-Dark";
      package = pkgs.catppuccin-gtk.override {
        variant = "mocha";
      };
    };
  };


  xdg.configFile = {
    "gtk-4.0/assets".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/assets";
    "gtk-4.0/gtk.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk.css";
    "gtk-4.0/gtk-dark.css".source = "${config.gtk.theme.package}/share/themes/${config.gtk.theme.name}/gtk-4.0/gtk-dark.css";
  };

  programs.home-manager.enable = true;
}
