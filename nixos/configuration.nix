{ inputs, config, pkgs, ... }:

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

 #  services.xserver.videoDrivers = [ "nvidia" ];
	#
 #  hardware.nvidia = {
 #    modesetting.enable = true;
 #    powerManagement.enable = false;
 #    powerManagement.finegrained = false;
 #    open = false;
 #    nvidiaSettings = true;
 #    package = config.boot.kernelPackages.nvidiaPackages.stable;
	#
 #    prime = {
 #        sync.enable = true;
	# 	intelBusId = "PCI:0:2:0";
	# 	nvidiaBusId = "PCI:1:0:0";
	# };
 #  };

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.tmp.cleanOnBoot = true;

  # disable nvidia
  boot.extraModprobeConfig = ''
    blacklist nouveau
    options nouveau modeset=0
  '';

  services.udev.extraRules = ''
    # Remove NVIDIA USB xHCI Host Controller devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c0330", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA USB Type-C UCSI devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x0c8000", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA Audio devices, if present
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x040300", ATTR{power/control}="auto", ATTR{remove}="1"
    # Remove NVIDIA VGA/3D controller devices
    ACTION=="add", SUBSYSTEM=="pci", ATTR{vendor}=="0x10de", ATTR{class}=="0x03[0-9]*", ATTR{power/control}="auto", ATTR{remove}="1"
  '';
  boot.blacklistedKernelModules = [ "nouveau" "nvidia" "nvidia_drm" "nvidia_modeset" ];



  networking.hostName = "nixos"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

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
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries = with pkgs; [
    # stdenv.cc.cc.lib
  ];

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
    brightnessctl
    eza
    tldr
    ripgrep
    python3
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
    discord
    nil
    mpv
    texliveFull
    zathura
    tlp
    chromium
    btop
    xdg-utils
    playerctl
    clang-tools
    rar
    # sof-firmware
    parallel
    obs-studio
    postgresql
    glxinfo
    socat
    hyprland
    firefox
    eww
    anki
    linux-firmware
    intel-gpu-tools
    libva-utils
    alsa-utils
  ];

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
  hardware.bluetooth.powerOnBoot = true;
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

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
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
