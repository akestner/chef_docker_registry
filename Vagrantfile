require 'vagrant'

VAGRANTFILE_API_VERSION = 2

# Vagrant Requirements
Vagrant.require_version '>= 1.4.0'

# Settings for guest VM
BOX_NAME_BASE = ENV['BOX_NAME_BASE'] || 'ubuntu64-12.04.3'
BOX_URL_BASE = ENV['BOX_URL_BASE'] || 'http://hgvagrant.s3.amazonaws.com/ubuntu64-12.04.3'
AWS_REGION = ENV['AWS_REGION'] || 'us-east-1'
AWS_AMI = ENV['AWS_AMI'] || 'ami-8f2718e6' # cannonical ubunutu 12.04LTS amd64, instance-store
AWS_INSTANCE_TYPE = ENV['AWS_INSTANCE_TYPE'] || 'c1.medium'
AWS_ACCESS_KEY_ID = ENV['AWS_ACCESS_KEY_ID'] || nil
AWS_SECRET_ACCESS_KEY = ENV['AWS_SECRET_ACCESS_KEY'] || nil
AWS_KEYPAIR_NAME = ENV['AWS_KEYPAIR_NAME'] || 'healthguru'
AWS_SSH_KEY = ENV['AWS_SSH_KEY'] || '~/.ssh/id_rsa'

VAGRANT_SSH_KEY = ENV['VAGRANT_SSH_KEY'] || nil
SSH_PASSWORD = 'vagrant'

RECIPES = ['hgdocker_registry::default']

Vagrant.configure(2) do |config|

    # setup vagrant for virtualbox provider (default)
    config.vm.provider :virtualbox do |vbox, override|
        # 'override' box name and url with provider-specific ones
        override.vm.box = "#{BOX_NAME_BASE}_virtualbox"
        override.vm.box_url = "#{BOX_URL_BASE}_virtualbox.box"
        vbox.gui = false
    end

    # setup vagrant for aws provider (use `vagrant up --provider=aws`)
    config.vm.provider :aws do |aws, override|
        # 'override' box name and url with provider-specific ones
        override.vm.box = "#{BOX_NAME_BASE}_aws"
        override.vm.box_url = "#{BOX_URL_BASE}_aws.box"

        override.ssh.username = 'ubuntu'
        override.ssh.private_key_path = AWS_SSH_KEY

        aws.access_key_id = AWS_ACCESS_KEY_ID
        aws.secret_access_key = AWS_SECRET_ACCESS_KEY
        aws.keypair_name = AWS_KEYPAIR_NAME

        aws.region = AWS_REGION
        aws.ami = AWS_AMI
        aws.instance_type = AWS_INSTANCE_TYPE

        aws.tags = {
            :Name => name.to_s
        }
    end

    # Use the specified private key path if it is specified and not empty.
    VAGRANT_SSH_KEY.nil? ?
        config.ssh.password = SSH_PASSWORD :
        config.ssh.private_key_path = VAGRANT_SSH_KEY

    # enable ssh agent forwarding
    config.ssh.forward_agent = true

    # resolve "stdin: is not a tty warning" for chef_solo provisioner
    # related issue and proposed fix: https://github.com/mitchellh/vagrant/issues/1673
    config.ssh.shell = 'bash -c \'BASH_ENV=/etc/profile exec bash\''

    # Chef-Solo Provisioner
    config.vm.provision 'chef_solo' do |chef|
        #chef.log_level = :debug
        #chef.verbose_logging = true
        chef.nfs = true
        chef.cookbooks_path = 'cookbooks'
        chef.roles_path = 'roles'
        chef.data_bags_path = 'data_bags'
        chef.environments_path = 'environments'

        chef.encrypted_data_bag_secret_key_path = File.expand_path('~/.chef/encrypted_data_bag_secret')
        chef.encrypted_data_bag_secret = "#{chef.provisioning_path}/encrypted_data_bag_secret"

        RECIPES.each do |recipe|
            chef.add_recipe(recipe)
        end

        chef.custom_config_path = 'chef_custom_config.rb'
    end


    # disable default vagrant synced_folder
    config.vm.synced_folder '.', '/vagrant', :disabled => true

end
