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
  # config.vm.box = "nixos/nixos-18.03-x86_64"
  # old, but still largely compatible
  config.vm.box = "ubuntu/xenial64"

  # config.vm.hostname = "vagrant-box"
  config.disksize.size = '40GB'

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
  if File.exists? "../shared"
    config.vm.synced_folder "../shared", "/vagrant_data"
  end

  if ARGV[0] == "ssh" and File.exists? PKEY_PATH then
    config.ssh.username = ENV['USER']
    config.ssh.private_key_path = PKEY_PATH
  end

  # config.vm.network "forwarded_port", guest: 80, host: 8080

  # private network with host-only access to the machine by IP
  # config.vm.network "private_network", ip: "192.168.33.10";
  # or use bridged network:
  config.vm.network "public_network"

  config.vm.provider "virtualbox" do |vb|
    # Display the VirtualBox GUI when booting the machine
    vb.gui = true
  
    # Customize the amount of memory on the VM:
    vb.memory = "3072"
    vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional'] 
  end
  
  if config.vm.box.start_with? "ubuntu" then
    ADMIN_GROUP_NAME = 'admin'
  else
    ADMIN_GROUP_NAME = 'wheel'
  end

  config.vm.provision :shell, inline: "rm -rf /tmp/setup"
  config.vm.provision :file, source: ".", destination: "/tmp/setup"

  config.vm.provision :shell do |sh|
    pubkeys = Dir["#{ENV['HOME']}/.ssh/*.pub"].collect {|f|
      File.read f
    }.join("\n")
    sh.inline = <<-EOF
        groupadd #{ENV['USER']} || true
        useradd --create-home #{ENV['USER']} -g #{ENV['USER']} --groups #{ADMIN_GROUP_NAME} || true
        if [ -e /etc/sudoers.d ]; then
          echo "#{ENV['USER']} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/#{ENV['USER']}
        fi

        MAINUSER=#{ENV['USER']}
        USERHOME=/home/$MAINUSER
        mkdir -p $USERHOME/.ssh
        chmod 700 $USERHOME/.ssh
        cat > $USERHOME/.ssh/authorized_keys <<EOF\n#{pubkeys}\nEOF
        chmod 644 $USERHOME/.ssh/authorized_keys
        chown -R $MAINUSER: $USERHOME/.ssh

        if [ ! -e $USERHOME/dot ]; then
          su - $MAINUSER -c 'git clone https://github.com/whacked/dot; cd dot; bash setup.sh'
        fi

        if [ ! -e /swap ]; then
          fallocate -l 4000M /swap
          chmod 600 /swap
          mkswap /swap
          swapon /swap
        fi
    EOF
  end

  if config.vm.box.start_with? "nixos" then
    config.vm.provision :shell do |sh|
      sh.inline = <<-EOF
        sudo nix-channel --add https://nixos.org/channels/nixos-18.09 nixos
        mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.orig
        cp /tmp/setup/configuration.vagrant.nix /etc/nixos/configuration.nix
        cp /tmp/setup/nix /etc/nixos/
        nix-shell -p dos2unix --run "dos2unix /etc/nixos/configuration.nix"
        nix-shell -p dos2unix --run "dos2unix /etc/nixos/nix/*"
        # sudo nixos-rebuild switch --upgrade
      EOF
    end
  end

  # <old>
  if File.exists? "../shared/authorized_keys"
    config.vm.provision :file do |file|
      file.source = "../shared/authorized_keys"
      file.destination = "/home/#{ENV['USER']}/vagrant-authorized_keys"
    end
  end

  if config.vm.box.start_with? "ubuntu" then
    config.vm.provision "shell", inline: <<-SHELL
      MAINUSER=#{ENV['USER']}
      USERHOME=/home/$MAINUSER
      LOGFILE=/tmp/$MAINUSER-vagrant-provision.log

      echo "=== CURRENT AUTHORIZED KEYS ==="
      cat $USERHOME/.ssh/authorized_keys

      if [ -e /vagrant_data/authorized_keys ]; then
        cat /vagrant_data/authorized_keys >> $USERHOME/.ssh/authorized_keys
        rm /vagrant_data/authorized_keys
      fi
      echo "=== UPDATED AUTHORIZED KEYS ==="
      cat $USERHOME/.ssh/authorized_keys

      # nix setup
      su - $MAINUSER -c "rsync -az /tmp/setup/ $USERHOME/setup/"
      su - $MAINUSER -c 'ln -sf $HOME/setup/nix $HOME/.nixpkgs'
      
      truncate -s 0 $LOGFILE
      chown $MAINUSER: $LOGFILE
      if [ ! -e /nix ]; then
        echo '=== INSTALL NIX ===' | tee -a $LOGFILE
        su - $MAINUSER -c "curl https://nixos.org/nix/install | sh" |& tee -a $LOGFILE
      fi
      echo '=== INSTALL PACKAGES ===' | tee -a $LOGFILE
      # prevent "cannot allocate memory"
      # https://github.com/NixOS/nix/issues/421
      echo 1 > /proc/sys/vm/overcommit_memory
      su - $MAINUSER -c '. $HOME/.nix-profile/etc/profile.d/nix.sh; NIXPKGS_ALLOW_UNFREE=1 nix-env -i my-custom-nixpkgs'
      
      which ansible
      # install python "natively" for on-host execution
      apt-get install -y python

      su - $MAINUSER -c '. $HOME/.nix-profile/etc/profile.d/nix.sh; sudo $(which ansible-playbook) -i localhost, $HOME/setup/playbook.yml'
    SHELL
  end
  # </old>
end
