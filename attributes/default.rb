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
    when 'production', 'prod'
        flavor = 'prod'
        storage = node[:docker_registry][:storage] || 's3'
    else
        flavor = 'dev'
        storage = node[:docker_registry][:storage] || 'local'
end

case storage
    when 'local'
        storage_path = "#{node[:docker_registry][:path]}/storage/#{flavor}"
    else
        storage_path = "registry/#{flavor}"
end

default[:docker_registry][:name] = 'docker_registry'
default[:docker_registry][:user] = 'docker_registry'
default[:docker_registry][:group] = 'docker_registry'

default[:docker_registry][:path] = "/opt/#{node[:docker_registry][:name]}"
default[:docker_registry][:registry_git_url] = 'https://github.com/dotcloud/docker-registry.git'
default[:docker_registry][:registry_git_ref] = 'master'
default[:docker_registry][:container_image] = 'samalba/docker-registry'
default[:docker_registry][:container_tag] = '0.1'
default[:docker_registry][:port_mapping] = {'5000' => '5000', '80' => '80'}
default[:docker_registry][:ports] = [node[:docker_registry][:port_mapping].map { |host, container| "#{host}:#{container}" }]

puts node[:docker_registry][:ports]

default[:docker_registry][:volumes] = ["#{node[:docker_registry][:path]}:/docker-registry"]
default[:docker_registry][:hostname] = node['hostname'] || node['fqdn'] || nil
default[:docker_registry][:detach] = true
default[:docker_registry][:tty] = false
default[:docker_registry][:publish_exposed_ports] = true
default[:docker_registry][:standalone] = true
default[:docker_registry][:init_type] = 'upstart'
default[:docker_registry][:init_template] = 'docker-container.conf.erb'
default[:docker_registry][:env_vars] = ["DOCKER_REGISTRY_CONFIG=/docker-registry/config/config.yml"]
default[:docker_registry][:index_url] = 'https://index.docker.io'
default[:docker_registry][:registry_url] = 'localhost'
default[:docker_registry][:registry_port] = 5000

default[:docker_registry][:data_bag] = node[:docker_registry][:name]
default[:docker_registry][:data_bag_item] = 'auth'

default[:docker_registry][:flavor] = flavor
default[:docker_registry][:storage] = storage
default[:docker_registry][:storage_path] = storage_path
default[:docker_registry][:secret_key] = nil
default[:docker_registry][:s3_access_key_id] = nil
default[:docker_registry][:s3_secret_access_key] = nil
default[:docker_registry][:s3_encrypt] = true
default[:docker_registry][:s3_secure] = true

default[:docker_registry][:nginx][:server_name] = 'localhost'
default[:docker_registry][:nginx][:port] = 80
default[:docker_registry][:nginx][:hosts] = [(node['ipaddress'] || '127.0.0.1')]
default[:docker_registry][:nginx][:owner] = node[:docker_registry][:user]
default[:docker_registry][:nginx][:group] = node[:docker_registry][:group]
default[:docker_registry][:nginx][:local_server] = true
default[:docker_registry][:nginx][:application_socket] = nil
default[:docker_registry][:nginx][:ssl] = false
default[:docker_registry][:nginx][:ssl_path] = '/etc/ssl'
default[:docker_registry][:nginx][:certificate_path] = nil
default[:docker_registry][:nginx][:certificate_key_path] = nil
default[:docker_registry][:nginx][:set_host_header] = true

