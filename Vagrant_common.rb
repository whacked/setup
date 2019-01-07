# -*- mode: ruby -*-
# vi: set ft=ruby :

PKEY_PATH = File.join ENV["HOME"], ".ssh", "id_rsa"
abort("No pkey found at #{PKEY_PATH}") if not File.exists? PKEY_PATH
