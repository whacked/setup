# -*- mode: ruby -*-
# vi: set ft=ruby :

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|
  # The most common configuration options are documented and commented below.
  # For a complete reference, please see the online documentation at
  # https://docs.vagrantup.com.

  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "nixos/nixos-18.03-x86_64"
  config.disksize.size = '40GB'

  # Disable automatic box update checking. If you disable this, then
  # boxes will only be checked for updates when the user runs
  # `vagrant box outdated`. This is not recommended.
  # config.vm.box_check_update = false

  # Create a forwarded port mapping which allows access to a specific port
  # within the machine from a port on the host machine. In the example below,
  # accessing "localhost:8080" will access port 80 on the guest machine.
  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # Create a private network, which allows host-only access to the machine
  # using a specific IP.
  # config.vm.network "private_network", ip: "192.168.33.10"

  # Create a public network, which generally matched to bridged network.
  # Bridged networks make the machine appear as another physical device on
  # your network.
  # config.vm.network "public_network"

  # Share an additional folder to the guest VM. The first argument is
  # the path on the host to the actual folder. The second argument is
  # the path on the guest to mount the folder. And the optional third
  # argument is a set of non-required options.
  # config.vm.synced_folder "../data", "/vagrant_data"

  # Provider-specific configuration so you can fine-tune various
  # backing providers for Vagrant. These expose provider-specific options.
  # Example for VirtualBox:
  #
  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
  
    # Customize the amount of memory on the VM:
    vb.memory = "3072"
  end
  #
  # View the documentation for the provider you are using for more
  # information on available options.

  config.vm.provision :shell do |sh|
    sh.inline = "sudo rm -rf /tmp/setup /etc/nixos/nix"
  end

  config.vm.provision :file, source: ".", destination: "/tmp/setup"

  config.vm.provision :shell do |sh|
    sh.inline = <<-EOF
      sudo nix-channel --add https://nixos.org/channels/nixos-18.09 nixos
      mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.orig
      mv /tmp/setup/configuration.vagrant.nix /etc/nixos/configuration.nix
      mv /tmp/setup/nix /etc/nixos/
      nix-shell -p dos2unix --run "dos2unix /etc/nixos/configuration.nix"
      nix-shell -p dos2unix --run "dos2unix /etc/nixos/nix/*"
      # sudo nixos-rebuild switch --upgrade
    EOF
  end
end
