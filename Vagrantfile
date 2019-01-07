# -*- mode: ruby -*-
# vi: set ft=ruby :

load 'Vagrant_common.rb'

# All Vagrant configuration is done below. The "2" in Vagrant.configure
# configures the configuration version (we support older styles for
# backwards compatibility). Please don't change it unless you know what
# you're doing.
Vagrant.configure(2) do |config|

  if false then
    required_plugins = %w( vagrant-vbguest vagrant-disksize vagrant-guest_ansible )
    required_plugins.each do |plugin|
        unless Vagrant.has_plugin? plugin
            system "vagrant plugin install #{plugin}"
        end
    end
  end
  
  # Every Vagrant development environment requires a box. You can search for
  # boxes at https://vagrantcloud.com/search.
  config.vm.box = "nixos/nixos-18.03-x86_64"
  # old, but still largely compatible
  # config.vm.box = "ubuntu/xenial64"

  # config.vm.hostname = "vagrant-box"
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
  # config.vm.box = "nixos/nixos-18.03-x86_64"

  if config.vm.box.start_with? "ubuntu" then
    config.ssh.username = 'ubuntu'
  end

  config.ssh.private_key_path = PKEY_PATH

  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # private network with host-only access to the machine by IP
  # config.vm.network "private_network", ip: "192.168.33.10";
  # or use bridged network:
  config.vm.network "public_network"

  # sync folder from `host, vbox`
  config.vm.synced_folder "../shared", "/vagrant_data"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
  
    # Customize the amount of memory on the VM:
    vb.memory = "3072"
    vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional'] 
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

      if [ ! -e /swap ]; then
        fallocate -l 4000M /swap
        chmod 600 /swap
        mkswap /swap
        swapon /swap
      fi
    EOF
  end

  if File.exists? "../shared/authorized_keys"
    config.vm.provision :file do |file|
      file.source = "../shared/authorized_keys"
      file.destination = "/home/#{config.ssh.username}/vagrant-authorized_keys"
    end
  end

  if File.exists? "../shared/setup"
    config.vm.provision :file do |file|
      file.source = "."  # path to `setup`
      file.destination = "/home/#{config.ssh.username}/setup"
    end
  end

  if config.vm.box.start_with? "ubuntu" then
    config.vm.provision "shell", inline: <<-SHELL
      USERNAME=#{config.ssh.username}
      USERHOME=/home/$USERNAME
      LOGFILE=$USERHOME/vagrant-provision.log

      echo "=== CURRENT AUTHORIZED KEYS ==="
      cat $USERHOME/.ssh/authorized_keys
      echo "=== UPDATED AUTHORIZED KEYS ==="

      if [ -e /vagrant_data/authorized_keys ]; then
        cat /vagrant_data/authorized_keys >> $USERHOME/.ssh/authorized_keys
        rm /vagrant_data/authorized_keys
      fi

      # nix setup
      truncate -s 0 $LOGFILE
      chown $USERNAME: $LOGFILE
      echo '=== INSTALL NIX ===' >> $LOGFILE
      su $USERNAME -c "cd $USERHOME && sh <(curl https://nixos.org/nix/install) --no-daemon >> $LOGFILE 2>&1"
      # bootstrap from github:
      # su $USERNAME -c "cd $USERHOME && git clone https://github.com/whacked/setup >> $LOGFILE 2>&1"
      su $USERNAME -c "cd $USERHOME && ln -s setup/nix .nixpkgs"
      echo '=== INSTALL PACKAGES ===' >> $LOGFILE
      su $USERNAME -c ". $USERHOME/.nix-profile/etc/profile.d/nix.sh; nix-env -i all"
      
      which ansible
      # install python "natively" for on-host execution
      apt-get install -y python

      cd $USERHOME/setup
      export ANSIBLE_HOST_KEY_CHECKING=False
      cp playbook.yml playbook.yml.orig
      cat playbook.yml.orig |
        sed 's|user:.*|connection: local|' |
        cat > playbook.yml
      su $USERNAME -c '. /home/#{config.ssh.username}/.nix-profile/etc/profile.d/nix.sh; sudo $(which ansible-playbook) -i localhost, playbook.yml'
    SHELL
  end
end
