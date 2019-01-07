# see https://github.com/nix-community/nixbox/blob/master/scripts/configuration.nix
{ config, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./vagrant.nix
    ];

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.device = "/dev/sda";

  # remove the fsck that runs at startup. It will always fail to run, stopping
  # your boot until you press *.
  boot.initrd.checkJournalingFS = false;

  # Services to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # Enable DBus
  services.dbus.enable    = true;

  # Replace nptd by timesyncd
  services.timesyncd.enable = true;

  # Enable guest additions.
  virtualisation.virtualbox.guest.enable = true;

  # https://nixos.wiki/wiki/Xfce#Using_as_a_desktop_manager_and_not_a_window_manager
  # Enable pulseaudio
  nixpkgs.config.pulseaudio = true;
  services.xserver = {
      enable = true;
      # (lightdm: more featureful login screen)
      displayManager.lightdm = {
          enable = true;
          autoLogin.enable = true;
          autoLogin.user = "vagrant";
      };
      desktopManager = {
          default = "xfce";
          xterm.enable = false;
          xfce.enable = true;
      };
      windowManager = {
          default = "xmonad";
          xmonad.enable = true;
          xmonad.enableContribAndExtras = true;
      };
  };

  environment.variables.EDITOR = "vim";

  # Packages for Vagrant
  environment.systemPackages = with pkgs; [
    findutils
    gnumake
    iputils
    jq
    nettools
    netcat
    nfs-utils
    rsync
    linuxPackages.virtualboxGuestAdditions
  ]
  ++ (import ./nix/util.nix)
  ++ (import ./nix/dev.nix)
  ++ (import ./nix/util.nix)
  ++ (import ./nix/desktop.nix)
  ++ (import ./nix/work.nix);

  # Creates a "vagrant" users with password-less sudo access
  users = {
    defaultUserShell = pkgs.zsh;
    extraGroups = [ { name = "vagrant"; } { name = "vboxsf"; } ];
    extraUsers  = [
      # Try to avoid ask password
      { name = "root"; password = "vagrant"; }
      {
        description     = "Vagrant User";
        name            = "vagrant";
        group           = "vagrant";
        extraGroups     = [ "users" "vboxsf" "wheel" ];
        password        = "vagrant";
        home            = "/home/vagrant";
        createHome      = true;
        useDefaultShell = true;
        # UPD
        # set default shell to zsh
        shell           = pkgs.zsh;
        openssh.authorizedKeys.keys = [
          "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA6NF8iallvQVp22WDkTkyrtvp9eWW6A8YVr+kz4TjGYe7gHzIw+niNltGEFHzD8+v1I2YJ6oXevct1YeS0o9HZyN1Q9qgCgzUFtdOKLv6IedplqoPkcmF0aYet2PkEDo3MlTBckFXPITAMzF8dJSIFo9D8HfdOV0IAdx4O7PtixWKn5y2hMNG0zQPyUecp4pzC6kivAIhyfHilFR61RGL+GPXQ2MWZWFYbAGjyiYJnAmCP3NOTd0jMZEnDkbUvxhMmBYSdETk1rRgm+R4LOzFUGaHqHDLKLX+FIPKcF96hrucXzcWyLbIbEgE98OHlnVYCzRdK8jlqm8tehUc9c9WhQ== vagrant insecure public key"
        ];
      }
    ];
  };

  nixpkgs.config.allowUnfree = true;

  programs.zsh.ohMyZsh = {
    enable = true;
    plugins = [ "git" "python" "man" ];
    theme = "crunch";
  };

  programs.zsh.enable = true;
  programs.zsh.interactiveShellInit = ''
    touch $HOME/.zshrc
    export ZSH=${pkgs.oh-my-zsh}/share/oh-my-zsh/

    # Customize your oh-my-zsh options here
    ZSH_THEME="cloud"
    plugins=(git)

    source $ZSH/oh-my-zsh.sh
  '';

  security.sudo.configFile =
    ''
      Defaults:root,%wheel env_keep+=LOCALE_ARCHIVE
      Defaults:root,%wheel env_keep+=NIX_PATH
      Defaults:root,%wheel env_keep+=TERMINFO_DIRS
      Defaults env_keep+=SSH_AUTH_SOCK
      Defaults lecture = never
      root   ALL=(ALL) SETENV: ALL
      %wheel ALL=(ALL) NOPASSWD: ALL, SETENV: ALL
    '';

  system.autoUpgrade.enable = true;
  system.autoUpgrade.channel = https://nixos.org/channels/nixos-18.09;
}

