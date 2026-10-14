# aws-dev: headless NixOS dev box on EC2 (infra/aws-dev), reached only over Tailscale.
# Deploy on the box itself: sudo nixos-rebuild switch --flake ~/.dotfiles#aws-dev
{ config, pkgs, ... }:
{
  imports = [
    ./ec2.nix
    ./fleet.nix
    ./idle-stop.nix
  ];

  networking.hostName = "aws-dev";
  time.timeZone = "Asia/Ho_Chi_Minh";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
    auto-optimise-store = true;
    # 8 GiB of RAM: one build at a time, so a source build cannot push agents into swap.
    max-jobs = 1;
    cores = 2;
  };
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Compressed swap in RAM: idle LSPs and agents page out cheaply on an 8 GiB box.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  users.users.schiffer = {
    isNormalUser = true;
    extraGroups = [
      "wheel"
      "docker"
    ];
    shell = pkgs.zsh;
    # Login is via Tailscale SSH (tailnet identity), so no authorized keys are needed.
  };
  security.sudo.wheelNeedsPassword = false;

  programs.zsh = {
    enable = true;
    enableGlobalCompInit = false; # .zshrc runs compinit
    promptInit = ""; # .zshrc runs starship
  };
  environment.pathsToLink = [ "/share/zsh" ]; # completions for home-manager packages

  # Access: Tailscale only. Nothing listens on the public interface except
  # WireGuard's UDP port, so Tailscale can use a direct path instead of DERP relays.
  # `sudo tailscale up --ssh` once (interactive browser login, no stored auth key).
  # Break-glass: SSM Session Manager (amazon-ssm-agent, enabled by ec2.nix).
  services.tailscale.enable = true;
  services.openssh = {
    enable = true;
    openFirewall = false; # reachable only on tailscale0
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "prohibit-password"; # bootstrap key; set to "no" once Tailscale works
    };
  };
  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true; # 50 GiB disk
  };

  # Foreign dynamically linked binaries: Claude Code (native installer), treehouse,
  # uv-downloaded Pythons, manylinux wheels, Mason leftovers.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      stdenv.cc.cc.lib
      zlib
      openssl
      icu
    ];
  };

  # kitty (xterm-kitty) and ghostty over SSH.
  environment.enableAllTerminfo = true;

  # The C toolchain lives in the system profile (treesitter parsers, native npm modules).
  environment.systemPackages = with pkgs; [
    gcc
    gnumake
  ];

  system.stateVersion = "26.05";
}
