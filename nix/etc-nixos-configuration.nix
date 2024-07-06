# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, lib, ... }:

let
  # copy / symlink this from ~/dot/user-config.nix
  userConfig = import /etc/nix/user-config.nix;
  setupConfig = import (/. + builtins.toPath "${userConfig.homeDirectory}/setup/nix/config.nix") { inherit pkgs; };
in {
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Bootloader.
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # Setup keyfile
  boot.initrd.secrets = {
    "/crypto_keyfile.bin" = null;
  };

  boot.loader.grub.enableCryptodisk=true;

  # boot.initrd.luks.devices.${userConfig.luksDeviceId}.keyFile = "/crypto_keyfile.bin";
  boot.initrd.luks.devices.${userConfig.luksDeviceId}.device = "/dev/disk/by-uuid/" + (builtins.replaceStrings ["luks-"] [""] userConfig.luksDeviceId);

  networking.hostName = userConfig.localHostName; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "${userConfig.timeZone}";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_US.UTF-8";
    LC_IDENTIFICATION = "en_US.UTF-8";
    LC_MEASUREMENT = "en_US.UTF-8";
    LC_MONETARY = "en_US.UTF-8";
    LC_NAME = "en_US.UTF-8";
    LC_NUMERIC = "en_US.UTF-8";
    LC_PAPER = "en_US.UTF-8";
    LC_TELEPHONE = "en_US.UTF-8";
    LC_TIME = "en_US.UTF-8";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    dpi = 300;  # this affects the login screen ONLY
    desktopManager = {
      xterm.enable = false;
      xfce = {
        enable = true;
        # noDesktop = true;
        # enableXfwm = false;
        enableXfwm = true;
      };
    };
    # this affects the desktop environment (terminal, UI, status bar, conky)
    displayManager.sessionCommands = ''
      # disable screen blank and screen off
      ${pkgs.xorg.xset}/bin/xset s off
      ${pkgs.xorg.xset}/bin/xset s noblank
      ${pkgs.xorg.xset}/bin/xset r rate 200 30
      ${pkgs.xorg.xrdb}/bin/xrdb -merge <<EOF
      Xft.dpi: 160
      EOF
    '';
    windowManager = {
      i3 = {
        enable = true;
        extraPackages = with pkgs; [
          dmenu
          i3status
        ];
      };
    };
  };
  services.displayManager = {
    defaultSession = "xfce+i3";
  };
  # enable compositor
  services.picom = {
    enable = true;
    # extraOptions = "--experimental-backends";
  };

  # needed for flatpak
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  };
  services.flatpak.enable = true;

  # enable remote management using RDP on linux
  services.xrdp = {
    enable = true;
  };

  fonts = {
    fontDir.enable = true;
    packages = with pkgs; [
      fira-code
      fira-code-nerdfont

      noto-fonts
      noto-fonts-cjk
      noto-fonts-emoji

    ];
  };


  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "";
    options = "ctrl:nocaps";  # set caps as ctrl
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  hardware.enableAllFirmware = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;  # enables the blueman widget in WM

  # Enable sound with pipewire.
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  environment.variables = {
    GDK_SCALE = "1.5";      # affects sizing of GDK apps: firefox, thunar, etc
    # GDK_DPI_SCALE = "0.6";
    XCURSOR_SIZE = "64";  # makes mouse cursor bigger
    # QT
    # QT_SCALE_FACTOR="1.5";
    # QT_AUTO_SCREEN_SCALE_FACTOR="0";
    # QT_FONT_DPI="144";
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
  # enable natural scrolling only for touchpad
  services.libinput.touchpad.naturalScrolling = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${userConfig.username} = {
    isNormalUser = true;
    description = userConfig.username;
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
    #  thunderbird
    ];
  };

  users.defaultUserShell = pkgs.zsh;

  # Install firefox.
  programs.firefox.enable = true;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    appimage-run
    bluez
    git
    htop
    tmux
    usbutils
    vim
    wget
    xorg.xmodmap
  ] ++ (import (/. + builtins.toPath "${userConfig.homeDirectory}/setup/nix/util.nix") { inherit pkgs; }) ++ [
  # ] ++ setupConfig.includeDefaultPackages ++ [
  ] ++ [
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;
  services.openssh.settings.PasswordAuthentication = false;

  # ref https://discourse.nixos.org/t/japanese-input-in-2023-2024/37274/13
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-chewing
      fcitx5-mozc
      fcitx5-gtk
    ];
  };

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
  system.stateVersion = "24.05"; # Did you read the comment?

  programs.zsh = {

    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
       enable = true;
       theme = "dieter";
       plugins = [
         "git"
         "history"
       ];

    };
    # make the shell run custom stuff
    # interactiveShellInit = ''...'';
  };

}
