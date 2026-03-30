# NixOS system configuration for general-purpose machines.
#
# Machine-specific settings are read from /etc/nix/user-config.nix.
# See nix/nixos/user-config.nix.example for the full schema.
#
# Bootstrap:
#   1. Clone the setup repo: git clone <repo> ~/setup
#   2. Create /etc/nix/user-config.nix from user-config.nix.example
#   3. sudo nixos-rebuild switch
#   4. home-manager switch   (as regular user)

{ config, pkgs, lib, ... }:

let
  # Machine-specific configuration — must exist before nixos-rebuild switch.
  userConfig = import /etc/nix/user-config.nix;

  username  = userConfig.username;
  userHome  = userConfig.homeDirectory or "/home/${username}";
  setupPath = userConfig.setupPath or "${userHome}/setup";

  # Package modules — util.nix always included; remaining groups opt-in via tags.
  toPath = rel: /. + "${setupPath}/${rel}";

  tagMap = {
    dev              = import (toPath "nix/dev.nix")              { inherit pkgs; };
    cloud            = import (toPath "nix/cloud.nix")            { inherit pkgs; };
    gui              = import (toPath "nix/gui.nix")              { inherit pkgs; };
    desktop          = import (toPath "nix/desktop.nix")          { inherit pkgs; };
    work             = import (toPath "nix/work.nix")             { inherit pkgs; };
    dev-heavy        = import (toPath "nix/dev-heavy.nix")        { inherit pkgs; };
    electron         = import (toPath "nix/electron.nix")         { inherit pkgs; };
    containerization = import (toPath "nix/containerization.nix") { inherit pkgs; };
    unfree           = import (toPath "nix/unfree.nix")           { inherit pkgs; };
    misc-utils       = [
      (pkgs.callPackage (import (toPath "nix/pkgs/development/tools/bootleg-prebuilt/default.nix")) {})
      (pkgs.callPackage (import (toPath "nix/pkgs/development/tools/jet/default.nix")) {})
      (pkgs.callPackage (import (toPath "nix/pkgs/development/tools/ck/default.nix")) {})
      (pkgs.callPackage (import (toPath "nix/pkgs/misc/ruffle-prebuilt/default.nix")) {})
    ];
  };

  unknownTags = builtins.filter (tag: !(tagMap ? ${tag})) (userConfig.tags or []);
  utilPkgs    = import (toPath "nix/util.nix") { inherit pkgs; };
  extraPkgs   = if unknownTags != []
    then builtins.throw "Unknown tags in user-config: ${lib.concatStringsSep ", " unknownTags}"
    else lib.concatMap (tag: tagMap.${tag}) (userConfig.tags or []);

in {
  imports = [
    ./hardware-configuration.nix
  ];

  # ---------------------------------------------------------------------------
  # Boot
  # ---------------------------------------------------------------------------
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "/dev/sda";
  boot.loader.grub.useOSProber = true;

  # ---------------------------------------------------------------------------
  # Networking
  # ---------------------------------------------------------------------------
  networking.hostName = userConfig.hostName or "nixos";
  networking.networkmanager.enable = true;

  # ---------------------------------------------------------------------------
  # Locale & timezone — read from user-config
  # ---------------------------------------------------------------------------
  time.timeZone      = userConfig.timeZone or "US/Pacific";
  i18n.defaultLocale = userConfig.locale or "en_US.UTF-8";

  # ---------------------------------------------------------------------------
  # Desktop (X11 + GNOME)
  # ---------------------------------------------------------------------------
  services.xserver.enable = true;
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;
  services.xserver.xkb = {
    layout  = "us";
    variant = "";
  };

  services.printing.enable = true;

  # Sound via PipeWire
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable            = true;
    alsa.enable       = true;
    alsa.support32Bit = true;
    pulse.enable      = true;
  };

  programs.firefox.enable = true;

  # ---------------------------------------------------------------------------
  # User account
  # ---------------------------------------------------------------------------
  users.users.${username} = {
    isNormalUser = true;
    description  = username;
    home         = userHome;
    extraGroups  = [ "networkmanager" "wheel" "docker" ];

    # SSH public keys fetched from GitHub on every nixos-rebuild switch.
    # Requires network access during build. User has physical console access
    # as fallback if key fetch fails.
    openssh.authorizedKeys.keyFiles = [
      (builtins.fetchurl "https://github.com/${userConfig.git.userName}.keys")
    ];
  };

  # ---------------------------------------------------------------------------
  # SSH — password login disabled; keys only
  # ---------------------------------------------------------------------------
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin        = "no";
    };
  };

  # ---------------------------------------------------------------------------
  # Docker — sudo-less management via docker group
  # ---------------------------------------------------------------------------
  virtualisation.docker = {
    enable           = true;
    autoPrune.enable = true;
  };

  # ---------------------------------------------------------------------------
  # Tailscale VPN — controlled by userConfig.tailscaleEnabled
  # ---------------------------------------------------------------------------
  services.tailscale.enable = userConfig.tailscaleEnabled or false;

  # ---------------------------------------------------------------------------
  # WireGuard VPN — controlled by userConfig.wireguardEnabled
  # Uncomment and fill in peers/addresses to activate.
  # ---------------------------------------------------------------------------
  # networking.wg-quick.interfaces = lib.mkIf (userConfig.wireguardEnabled or false) {
  #   wg0 = {
  #     address        = [ "10.0.0.1/24" ];
  #     privateKeyFile = "/etc/wireguard/private.key";
  #     peers          = [];
  #   };
  # };

  # ---------------------------------------------------------------------------
  # Nix settings
  # ---------------------------------------------------------------------------
  nixpkgs.config.allowUnfree = true;

  # ---------------------------------------------------------------------------
  # System packages
  # ---------------------------------------------------------------------------
  environment.systemPackages = [
    pkgs.home-manager   # standalone home-manager for user environment setup
  ]
  ++ utilPkgs
  ++ extraPkgs;

  # ---------------------------------------------------------------------------
  # State version — set at first install, do not change
  # ---------------------------------------------------------------------------
  system.stateVersion = "25.11";
}
