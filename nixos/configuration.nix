{ config, pkgs, upkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  hardware.opengl = {
    enable = true;
    driSupport = true;
    driSupport32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
    ];
  };

  environment.sessionVariables = {
      LIBVA_DRIVER_NAME = "iHD";
  };

  # services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false;
    powerManagement.finegrained = false;
    open = false;
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;

    prime = {
        sync.enable = true;
		intelBusId = "PCI:0:2:0";
		nvidiaBusId = "PCI:1:0:0";
	};
  };

  fileSystems."/home/schiffer/Documents/mnt" = {
    device = "/dev/disk/by-uuid/a2c43ddf-ede7-4127-aea9-43350329e82e";
    fsType = "ext4";
    options = [ "users" "nofail" "exec" ];
  };


  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  networking.hostName = "nixos";

  networking.dhcpcd.enable = false;
  networking.nameservers = [ "1.1.1.1" "1.0.0.1" ];
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  networking.networkmanager.enable = true;

  time.timeZone = "Asia/Ho_Chi_Minh";

  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "vi_VN";
    LC_IDENTIFICATION = "vi_VN";
    LC_MEASUREMENT = "vi_VN";
    LC_MONETARY = "vi_VN";
    LC_NAME = "vi_VN";
    LC_NUMERIC = "vi_VN";
    LC_PAPER = "vi_VN";
    LC_TELEPHONE = "vi_VN";
    LC_TIME = "vi_VN";
  };

  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
        fcitx5-gtk
        fcitx5-mozc
        fcitx5-unikey
    ];
  };

  services.xserver.xkb = {
    layout = "us";
    variant = "";
  };

  users.groups.pipewire = {};

  users.users.schiffer = {
    isNormalUser = true;
    description = "Vo Dinh Khanh";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "pipewire" ];
    # packages = with pkgs; [];
  };

  nixpkgs.config.allowUnfree = true;

  nix.optimise.automatic = true;
  nix.optimise.dates = [ "05:00" ];
  nix.settings.auto-optimise-store = true;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  # programs.nix-ld.enable = true;
  # programs.nix-ld.libraries = with pkgs; [
  # ];

  environment.systemPackages = with pkgs; [
    neovim
    lua
    kitty
    hyprpaper
    hyprpicker
    starship
    git
    gcc
    gnumake
    # stdenv.cc.cc.lib
    brightnessctl
    wget
    eza
    tldr
    ripgrep
    python312
    nodejs
    fzf
    wl-clipboard
    zip
    unzip
    jq
    pavucontrol
    grim
    slurp
    spotify
    gammastep
    rustup
    go
    stow
    libnotify
    mako
    # discord
    nil
    mpv
    # texliveFull
    zathura
    tlp
    chromium
    btop
    xdg-utils
    playerctl
    rar
    parallel
    obs-studio
    socat
    hyprland
    firefox
    eww
    anki
    vscodium
    unixtools.xxd
    cudaPackages_11.cudatoolkit

    hcxdumptool
    hcxtools
    hashcat
  ] ++ (with upkgs; [
    discord
  ]);

  fonts.packages = with pkgs; [
    jetbrains-mono
    nerdfonts
    noto-fonts-cjk-sans
  ];

  programs.zsh = {
    enable = true;
    histFile = "$XDG_CACHE_HOME/zsh/history";
    histSize = 100;
  };
  programs.zsh.autosuggestions.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;

  users.defaultUserShell = pkgs.zsh;

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
  };


  xdg.portal = {
      enable = true;
      config.common.default = [
        "hyprland"
        "gtk"
      ];
      extraPortals = with pkgs; [
          xdg-desktop-portal-hyprland
          xdg-desktop-portal-gtk
      ];
  };

  programs.tmux = {
    enable = true;
    plugins = with pkgs.tmuxPlugins; [
      nord
      resurrect
      continuum
      sensible
    ];
  };

  programs.direnv = {
    enable = true;
    package = pkgs.direnv;
    silent = false;
    loadInNixShell = true;
    direnvrcExtra = "";
    nix-direnv = {
      enable = true;
      package = pkgs.nix-direnv;
    };
  };

  virtualisation.docker.rootless = {
    enable = true;
    setSocketVariable = true;
  };

  sound.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = false;
  services.blueman.enable = true;
  hardware.enableAllFirmware = true;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # services.openvpn.servers = {
  #   officeVPN  = { config = '' config /home/schiffer/.config/uit-student.ovpn ''; };
  # };

  services.openssh = {
    enable = true;
    ports = [ 22 ];
    settings = {
      PasswordAuthentication = true;
      AllowUsers = null; # Allows all users by default. Can be [ "user1" "user2" ]
      UseDns = true;
      X11Forwarding = false;
      PermitRootLogin = "no"; # "yes", "without-password", "prohibit-password", "forced-commands-only", "no"
    };
  };
  services.tlp.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.11"; # Did you read the comment?
}
