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
    only_if "! egrep -i \"^#{node[:docker_registry][:group]}\" /etc/group"
end

user node[:docker_registry][:owner] do
    gid node[:docker_registry][:group]
    home node[:docker_registry][:path]
    shell '/bin/bash'
    only_if "! getent passwd #{node[:docker_registry][:owner]} 2>&1 > /dev/null"
end

directory node[:docker_registry][:path] do
    owner node[:docker_registry][:owner]
    group node[:docker_registry][:group]
    recursive true
    mode 0776
    action :create
end

data_bag = DockerRegistry.decrypt_data_bag(
    node[:docker_registry][:data_bag],
    node[:docker_registry][:data_bag_item],
    ::Chef::Config[:encrypted_data_bag_secret]
)

template "#{node[:docker_registry][:path]}/shared/config.yml" do
    source 'config.yml.erb'
    mode 0440
    owner node[:docker_registry][:owner]
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

