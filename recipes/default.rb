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
end

user node[:docker_registry][:user] do
    gid node[:docker_registry][:group]
    home node[:docker_registry][:path]
    shell '/bin/bash'
    action :create
end

directory node[:docker_registry][:path] do
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    recursive true
    mode 0776
    action :create
end

if node[:docker_registry][:storage] == 'local'
    directory node[:docker_registry][:storage_path] do
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

template "#{node[:docker_registry][:path]}/config.yml" do
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
    detach node[:docker_registry][:detach]
    publish_exposed_ports node[:docker_registry][:publish_exposed_ports]
    tty node[:docker_registry][:tty]
    hostname node[:docker_registry][:hostname]
    port node[:docker_registry][:ports]
    env node[:docker_registry][:env_vars]
    volume node[:docker_registry][:volumes]
    init_type node[:docker_registry][:init_type]
    init_template node[:docker_registry][:init_template]
    action :run
end
