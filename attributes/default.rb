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

node.default[:docker_registry][:name] = 'docker_registry'
node.default[:docker_registry][:owner] = 'docker_registry'
node.default[:docker_registry][:group] = 'docker_registry'
node.default[:docker_registry][:path] = "/opt/#{node[:docker_registry][:name]}"

node.default[:docker_registry][:data_bag] = node[:docker_registry][:name]
node.default[:docker_registry][:data_bag_item] = node.chef_environment || 'development'

node.default[:docker_registry][:flavor] = node.chef_environment || 'development'
node.default[:docker_registry][:storage] = 's3'
node.default[:docker_registry][:storage_path] = "registry/#{node[:docker_registry][:flavor]}"
node.default[:docker_registry][:secret_key] = nil
node.default[:docker_registry][:s3_access_key_id] = nil
node.default[:docker_registry][:s3_secret_access_key] = nil
node.default[:docker_registry][:s3_encrypt] = true
node.default[:docker_registry][:s3_secure] = true
node.default[:docker_registry][:standalone] = true
node.default[:docker_registry][:index_endpoint] = 'https://index.docker.io'

node.default[:docker_registry][:nginx][:server_name] = 'localhost'
node.default[:docker_registry][:nginx][:port] = 80
node.default[:docker_registry][:nginx][:hosts] = [(node['ipaddress'] || '127.0.0.1')]
node.default[:docker_registry][:nginx][:owner] = node[:docker_registry][:owner]
node.default[:docker_registry][:nginx][:group] = node[:docker_registry][:group]
node.default[:docker_registry][:nginx][:local_server] = true
node.default[:docker_registry][:nginx][:application_socket] = nil
node.default[:docker_registry][:nginx][:ssl] = false
node.default[:docker_registry][:nginx][:ssl_path] = '/etc/ssl'
node.default[:docker_registry][:nginx][:certificate_path] = nil
node.default[:docker_registry][:nginx][:certificate_key_path] = nil
node.default[:docker_registry][:nginx][:set_host_header] = true

