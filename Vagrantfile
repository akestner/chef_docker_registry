# -*- mode: ruby -*-
# vi: set ft=ruby :

require 'vagrant'

VAGRANTFILE_API_VERSION = 2

# Vagrant Requirements
Vagrant.require_version ">= 1.4.0"

#  plugins config
Vagrant.require_plugin 'vagrant-berkshelf'
Vagrant.require_plugin 'vagrant-omnibus'

VM_NAME = 'docker-registry'
BOX_NAME_BASE = 'ubuntu64-12.04.3'
BOX_URL_BASE = 'http://hgvagrant.s3.amazonaws.com/ubuntu64-12.04.3'
VAGRANT_SSH_KEY = ENV['VAGRANT_SSH_KEY']
SSH_USERNAME = 'vagrant'
SSH_PASSWORD = 'vagrant'

Vagrant.configure(VAGRANTFILE_API_VERSION) do |global_config|

    global_config.berkshelf.enabled = true
    global_config.omnibus.enabled = true
    global_config.omnibus.chef_version = :latest

    global_config.vm.define VM_NAME do |config|

        config.vm.hostname = VM_NAME

        config.vm.network :private_network, ip: '192.168.33.233'

        config.ssh.username = SSH_USERNAME
        # Use the specified private key path if it is specified and not empty.
        VAGRANT_SSH_KEY.nil? ?
            config.ssh.password = SSH_PASSWORD :
            config.ssh.private_key_path = VAGRANT_SSH_KEY
        config.ssh.forward_agent = true

        # setup vagrant for virtualbox provider (default)
        config.vm.provider :virtualbox do |vbox, override|
            # 'override' box name and url with provider-specific ones
            override.vm.box = "#{BOX_NAME_BASE}_virtualbox"
            override.vm.box_url = "#{BOX_URL_BASE}_virtualbox.box"

            vbox.name = VM_NAME
            vbox.gui = false
            vbox.customize [
                'modifyvm', :id,
                '--memory', 1024,
                '--cpus', 2,
                '--natdnshostresolver1', 'on',
                '--natdnsproxy1', 'on'
            ]
        end

        # disable default vagrant synced_folder
        config.vm.synced_folder '.', '/vagrant', :disabled => true
        config.vm.provision :shell, :inline => 'ulimit -n 10000'

        # resolve "stdin: is not a tty warning" for chef_solo provisioner
        # related issue and proposed fix: https://github.com/mitchellh/vagrant/issues/1673
        #config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"

        # An array of symbols representing groups of cookbook described in the Vagrantfile
        # to exclusively install and copy to Vagrant's shelf.
        # config.berkshelf.only = []

        # An array of symbols representing groups of cookbook described in the Vagrantfile
        # to skip installing and copying to Vagrant's shelf.
        # config.berkshelf.except = []

        config.vm.provision :chef_solo do |chef|
            chef.log_level = :info
            chef.nfs = true
            chef.cookbooks_path = 'cookbooks'

            #chef.encrypted_data_bag_secret_key_path = File.expand_path('~/.chef/encrypted_data_bag_secret')
            #chef.encrypted_data_bag_secret = "#{chef.provisioning_path}/encrypted_data_bag_secret"

            ['docker-registry::application', 'docker-registry::default'].each do |recipe|
                chef.add_recipe recipe
            end

            chef.json = {
                'docker-registry' => {
                    :owner => 'vagrant',
                    :group => 'vagrant'
                }
            }

            chef.custom_config_path = 'chef_streaming_fix.rb'
        end
    end
end
