#
# Cookbook Name:: docker_registry
# Attributes:: default
#
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

include_attribute 'docker::default'

case node.chef_environment.to_s
    when 'default', 'development', 'dev'
        flavor = 'dev'
        storage = 'local'
    when 'production', 'prod'
        flavor = 'prod'
        storage = 's3'
    else
        flavor = 'common'
        storage = 'local'
end

case storage
    when 'local'
        storage_path = "#{node[:docker_registry][:path]}/docker-registry/storage/#{flavor}"
    else
        storage_path = "registry/#{flavor}"
end

node.default[:docker_registry][:name] = 'docker_registry'
node.default[:docker_registry][:user] = 'docker_registry'
node.default[:docker_registry][:group] = 'docker_registry'
node.default[:docker_registry][:path] = "/opt/#{node[:docker_registry][:name]}"
node.default[:docker_registry][:registry_git_url] = 'https://github.com/dotcloud/docker-registry.git'
node.default[:docker_registry][:registry_git_ref] = 'master'
node.default[:docker_registry][:container_image] = 'samalba/docker-registry'
node.default[:docker_registry][:container_tag] = '0.1'
node.default[:docker_registry][:port] = 5000
node.default[:docker_registry][:env_vars] = ["DOCKER_REGISTRY_CONFIG=#{node[:docker_registry][:path]}/config.yml"]
node.default[:docker_registry][:index_url] = 'https://index.docker.io'
node.default[:docker_registry][:registry_url] = node[:docker_registry][:nginx][:server_name]

node.default[:docker_registry][:data_bag] = node[:docker_registry][:name]
node.default[:docker_registry][:data_bag_item] = 'auth'

node.default[:docker_registry][:flavor] = flavor
node.default[:docker_registry][:storage] = storage
node.default[:docker_registry][:storage_path] = storage_path
node.default[:docker_registry][:secret_key] = nil
node.default[:docker_registry][:s3_access_key_id] = nil
node.default[:docker_registry][:s3_secret_access_key] = nil
node.default[:docker_registry][:s3_encrypt] = true
node.default[:docker_registry][:s3_secure] = true

node.default[:docker_registry][:nginx][:server_name] = 'localhost'
node.default[:docker_registry][:nginx][:port] = 80
node.default[:docker_registry][:nginx][:hosts] = [(node['ipaddress'] || '127.0.0.1')]
node.default[:docker_registry][:nginx][:owner] = node[:docker_registry][:user]
node.default[:docker_registry][:nginx][:group] = node[:docker_registry][:group]
node.default[:docker_registry][:nginx][:local_server] = true
node.default[:docker_registry][:nginx][:application_socket] = nil
node.default[:docker_registry][:nginx][:ssl] = false
node.default[:docker_registry][:nginx][:ssl_path] = '/etc/ssl'
node.default[:docker_registry][:nginx][:certificate_path] = nil
node.default[:docker_registry][:nginx][:certificate_key_path] = nil
node.default[:docker_registry][:nginx][:set_host_header] = true

