#
# Cookbook Name:: docker_registry
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

include_recipe 'docker::default'

group node[:docker_registry][:group] do
    action :create
    #only_if "! egrep -i \"^#{node[:docker_registry][:group]}\" /etc/group"
end

user node[:docker_registry][:user] do
    gid node[:docker_registry][:group]
    home node[:docker_registry][:path]
    shell '/bin/bash'
    #only_if "! getent passwd #{node[:docker_registry][:user]} 2>&1 > /dev/null"
end

directory node[:docker_registry][:path] do
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    recursive true
    mode 0776
    action :create
end

# clone the docker-registry source
git "#{node[:docker_registry][:path]}/docker-registry" do
    repository node[:docker_registry][:registry_git_url]
    reference node[:docker_registry][:registry_git_ref]
    user node[:docker_registry][:user]
    group node[:docker_registry][:group]
    action :sync
end

if node[:docker_registry][:storage] == 'local'
    directory "#{node[:docker_registry][:path]}/docker-registry/storage" do
        owner node[:docker_registry][:user]
        group node[:docker_registry][:group]
        recursive true
        mode 0776
        action :create
    end
end

data_bag = DockerRegistry.decrypt_data_bag(
    node[:docker_registry][:data_bag],
    node[:docker_registry][:data_bag_item],
    ::Chef::Config[:encrypted_data_bag_secret]
)

directory "#{node[:docker_registry][:path]}/docker-registry/config" do
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    recursive true
    mode 0776
    action :create
end

template "#{node[:docker_registry][:path]}/docker-registry/config/config.yml" do
    source 'registry_config.yml.erb'
    mode 0440
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    variables({
        :secret_key => data_bag[:secret_key],
        :storage => node[:docker_registry][:storage],
        :storage_path => node[:docker_registry][:storage_path],
        :standalone => node[:docker_registry][:standalone],
        :index_endpoint => node[:docker_registry][:index_endpoint],
        :s3_access_key_id => data_bag[:s3_access_key_id],
        :s3_secret_access_key => data_bag[:s3_secret_access_key],
        :s3_bucket => node[:docker_registry][:s3_bucket],
        :s3_encrypt => node[:docker_registry][:s3_encrypt],
        :s3_secure => node[:docker_registry][:s3_secure]
    })
end

# pull the latest image
docker_image node[:docker_registry][:container_image]

# run container, exposing ports
docker_container node[:docker_registry][:name] do
    image node[:docker_registry][:container_image]
    tag node[:docker_registry][:container_tag]
    user node[:docker_registry][:user]
    detach true
    publish_exposed_ports true
    tty true
    hostname (node['hostname'] || node['fqdn'])
    port "#{node[:docker_registry][:port]}:#{node[:docker_registry][:port]}"
    env node[:docker_registry][:env_vars]
    volume "#{::File.expand_path(node[:docker_registry][:path])}/docker-registry:/docker-registry"
    action :run
end


