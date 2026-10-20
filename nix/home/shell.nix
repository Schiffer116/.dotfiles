# zsh, starship, direnv, tmux. The config files stay in the repo (linked, not generated);
# only plugins.zsh is generated. zsh itself comes from pacman.
{ config, pkgs, ... }:
let
  link = config.lib.dotfiles.link;
  # Not in nixpkgs; same version as the AUR package.
  autoNotify = pkgs.fetchFromGitHub {
    owner = "MichaelAquilina";
    repo = "zsh-auto-notify";
    rev = "0.11.1";
    hash = "sha256-1+HD4rerEu0uu4hWtMORBeAJJgIgXv65McnqOpaSIV8=";
  };
in
{
  home.file.".zshenv".source = link ".zshenv";
  xdg.configFile."zsh/.zshrc".source = link ".config/zsh/.zshrc";
  xdg.configFile."zsh/_eww".source = link ".config/zsh/_eww";

  # Sourced by .zshrc. auto-notify needs a notification daemon, so only in a graphical session.
  xdg.configFile."zsh/plugins.zsh".text = ''
    source ${pkgs.zsh-syntax-highlighting}/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
    source ${pkgs.zsh-autosuggestions}/share/zsh-autosuggestions/zsh-autosuggestions.zsh
    [[ -n $WAYLAND_DISPLAY ]] && source ${autoNotify}/auto-notify.plugin.zsh
    source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
  '';

  xdg.configFile."starship.toml".source = link ".config/starship.toml";

  # Only tmux.conf is linked: TPM plugins and resurrect state stay out of the repo.
  xdg.configFile."tmux/tmux.conf".source = link ".config/tmux/tmux.conf";

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    enableZshIntegration = false; # .zshrc already runs `direnv hook`
  };

  home.packages = with pkgs; [
    starship
    tmux
  ];
}
