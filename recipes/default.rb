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

unless node[:docker_registry][:user] == 'root'
    group node[:docker_registry][:group] do
        action :create
    end

    user node[:docker_registry][:user] do
        gid node[:docker_registry][:group]
        home "/home/#{node[:docker_registry][:user]}"
        shell '/bin/bash -l'
        action :create
    end

    group 'sudo' do
        members node[:docker_registry][:user]
        append true
        action :modify
    end
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

git node[:docker_registry][:path] do
    repository node[:docker_registry][:registry_git_url]
    reference node[:docker_registry][:registry_git_ref]
    user node[:docker_registry][:user]
    group node[:docker_registry][:group]
    action :sync
end

data_bag = DockerRegistry.decrypt_data_bag(
    node[:docker_registry][:data_bag],
    node[:docker_registry][:data_bag_item],
    ::Chef::Config[:encrypted_data_bag_secret]
)

template "#{node[:docker_registry][:path]}/config/config.yml" do
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

template "#{node[:docker_registry][:path]}/Dockerfile" do
    source 'Dockerfile.erb'
    mode 0755
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    variables({
    })
end

# build our image
docker_image node[:docker_registry][:name] do
    source node[:docker_registry][:path]
    tag node[:docker_registry][:name]
    rm true
    action :build
end

export_path = ::File.join(node[:docker_registry][:path], '..', "#{node[:docker_registry][:name]}.tgz").to_s

# export it to a tarball for a moment
docker_image node[:docker_registry][:name] do
    destination export_path
    action :save
end

# run the registry container (our new private repo)
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

# import the tarball we exported earlier
docker_image node[:docker_registry][:name] do
    source export_path
    action :import
end

# tag our image into the new repo
docker_image node[:docker_registry][:name] do
    registry "#{node[:docker_registry][:registry_url]}:5000/"
    tag '0.0.1'
end
