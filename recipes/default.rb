#
# Cookbook Name:: docker-registry
# Recipe:: default
# Author:: Alex Kestner <akestner@healthguru.com>
#
# Copyright 2013, Alex Kestner
#
# Licensed under the Apache License, Version 2.0 (the 'License');
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an 'AS IS' BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe 'application'
include_recipe 'application_python'
include_recipe 'application_nginx'


group node['docker-registry'][:group] do
    action :create
    only_if "! egrep -i \"^#{node['docker-registry'][:group]}\" /etc/group"
end

user node['docker-registry'][:owner] do
    gid node['docker-registry'][:group]
    home node['docker-registry'][:install_dir]
    shell '/bin/bash'
    only_if "! getent passwd #{node['docker-registry'][:owner]}"
end

directory node['docker-registry'][:install_dir] do
    owner node['docker-registry'][:owner]
    group node['docker-registry'][:group]
    recursive true
    mode 0776
    action :create
end

directory node['docker-registry'][:storage_path] do
    owner node['docker-registry'][:owner]
    group node['docker-registry'][:group]
    recursive true
    mode 0776
    action :create
end


application "#{node['docker-registry'][:application_name]}" do
    name node['docker-registry'][:application_name]
    owner node['docker-registry'][:owner]
    group node['docker-registry'][:group]
    path node['docker-registry'][:install_dir]
    repository node['docker-registry'][:repository]
    revision node['docker-registry'][:tag]
    packages node['docker-registry'][:packages]

    action :force_deploy
    symlinks 'config.yml' => 'config.yml'

    before_migrate do

        data_bag = decrypt_data_bag(
            node['docker-registry'][:data_bag],
            node['docker-registry'][:data_bag_item],
            Chef::Config[:encrypted_data_bag_secret]
        )

        template "#{new_resource.path}/shared/config.yml" do
            source 'config.yml.erb'
            mode 0440
            owner node['docker-registry'][:owner]
            group node['docker-registry'][:group]
            variables({
                :secret_key => data_bag[:secret_key],
                :storage => node['docker-registry'][:storage],
                :storage_path => node['docker-registry'][:storage_path],
                :standalone => node['docker-registry'][:standalone],
                :index_endpoint => node['docker-registry'][:index_endpoint],
                :s3_access_key_id => data_bag[:s3_access_key_id],
                :s3_secret_access_key => data_bag[:s3_secret_access_key],
                :s3_bucket => node['docker-registry'][:s3_bucket],
            })
        end
    end

    virtualenv_path = ENV['WORKON_HOME'] || '~/.virtualenvs'

    Chef::Log "docker-registry/recipe/default.rb:: virtualenv_path => #{virtualenv_path}"
    Chef::Log "docker-registry/recipe/default.rb:: ENV['WORKON_HOME'] => #{ENV['WORKON_HOME']}"
    Chef::Log "docker-registry/recipe/default.rb:: directory => #{directory}"

    # make sure virtualenv has a place to work
    directory File.expand_path(virtualenv_path) do

        Chef::Log "docker-registry/recipe/default.rb:: directory => #{directory}"
        Chef::Log "docker-registry/recipe/default.rb:: virtualenv_path => #{virtualenv_path}"

        owner node['docker-registry'][:owner]
        group node['docker-registry'][:group]
        recursive true
        mode 0777
        action :create
    end

    gunicorn_working_dir = File.expand_path(node['docker-registry'][:working_dir])

    Chef::Log "docker-registry/recipe/default.rb:: node['docker-registry'][:working_dir] => #{node['docker-registry'][:working_dir]}"
    Chef::Log "docker-registry/recipe/default.rb:: gunicorn_working_dir => #{gunicorn_working_dir}"
    Chef::Log "docker-registry/recipe/default.rb:: gunicorn => #{gunicorn}"

    # make sure gunicorn has a place to work
    directory gunicorn_working_dir do

        Chef::Log "docker-registry/recipe/default.rb:: directory => #{directory}"
        Chef::Log "docker-registry/recipe/default.rb:: gunicorn_working_dir => #{gunicorn_working_dir}"

        owner node['docker-registry'][:owner]
        group node['docker-registry'][:group]
        recursive true
        mode 0777
        action :create
    end

    gunicorn do
        only_if { node['roles'].include? node['docker-registry'][:application_python_role] }
        max_requests node['docker-registry'][:max_requests]
        timeout node['docker-registry'][:timeout]
        port node['docker-registry'][:internal_port]
        workers node['docker-registry'][:workers]
        worker_class 'gevent'
        app_module 'wsgi:application'
        debug true
        virtualenv virtualenv_path
        environment :SETTINGS_FLAVOR => node['docker-registry'][:flavor]
        directory node['docker-registry'][:working_dir]
    end

    nginx_load_balancer do
        only_if { node['roles'].include? node['docker-registry'][:application_nginx_role] }
        application_port node['docker-registry'][:internal_port]
        application_server_role node['docker-registry'][:application_python_role]
        server_name node['docker-registry'][:server_name]
        set_host_header node['docker-registry'][:set_host_header]
        ssl node['docker-registry'][:ssl]

        template "#{node['docker-registry'][:application_name]}_nginx.conf.erb"
        mode 0755
        owner node['docker-registry'][:owner]
        group node['docker-registry'][:group]
        if node['docker-registry'][:ssl]
            certificate = ssl_certificate(
                node['docker-registry'][:data_bag],
                node['docker-registry'][:data_bag_item],
                Chef::Config[:encrypted_data_bag_secret]
            )
            variables({
                :ssl_certificate => certificate[:path],
                :ssl_certificate_key => certificate[:key_path]
            })
        end
    end
end
