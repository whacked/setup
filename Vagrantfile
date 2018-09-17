# -*- mode: ruby -*-
# vi: set ft=ruby :

load 'Vagrant_common.rb'

Vagrant.configure("2") do |config|

  required_plugins = %w( vagrant-vbguest vagrant-disksize vagrant-guest_ansible )
  required_plugins.each do |plugin|
      unless Vagrant.has_plugin? plugin
          system "vagrant plugin install #{plugin}"
      end
  end
  
  # config.vm.box = "nixos/nixos-18.03-x86_64"
  config.vm.box = "ubuntu/xenial64"

  config.vm.hostname = "vagrant-box"
  config.disksize.size = "40GB"

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
  end

  config.vm.provision "shell", inline: <<-SHELL
    rm -rf /home/#{config.ssh.username}/setup
  SHELL

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
