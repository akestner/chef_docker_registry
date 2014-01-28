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

# core docker config
default[:docker_registry][:name] = 'docker_registry'
default[:docker_registry][:user] = 'docker_registry'
default[:docker_registry][:group] = 'docker_registry'
default[:docker_registry][:path] = "/opt/#{node[:docker_registry][:name]}"
default[:docker_registry][:port] = 5000
default[:docker_registry][:url] = node['hostname'] || node['fqdn'] || node[:docker_registry][:name]
default[:docker_registry][:init_type] = 'upstart'
default[:docker_registry][:init_template] = 'docker-container.conf.erb'
default[:docker_registry][:bind_socket] = "/var/run/#{node[:docker_registry][:name]}.sock"
default[:docker_registry][:socket_template] = 'docker-container.socket.erb'
default[:docker_registry][:dockerfile_template] = 'Dockerfile.erb'

# docker-registry specifics
default[:docker_registry][:flavor] = flavor
default[:docker_registry][:storage] = storage
default[:docker_registry][:storage_path] = storage_path
default[:docker_registry][:container_name] = 'docker_registry'
default[:docker_registry][:container_tag] = '0.0.1'
default[:docker_registry][:repository] = "#{node[:docker_registry][:url]}:#{node[:docker_registry][:port]}/"

# are we building a docker-registry container?
default[:docker_registry][:build_registry] = false

# authentication/data_bags/s3
default[:docker_registry][:data_bag] = node[:docker_registry][:name]
default[:docker_registry][:data_bag_item] = 'auth'
# these attributes must
default[:docker_registry][:secret_key] = nil
default[:docker_registry][:s3_access_key_id] = nil
default[:docker_registry][:s3_secret_access_key] = nil

default[:docker_registry][:s3_encrypt] = true
default[:docker_registry][:s3_secure] = true

# docker container mappings -- ports, directories, environment vars
default[:docker_registry][:ports] = { node[:docker_registry][:port].to_s => node[:docker_registry][:port].to_s }
default[:docker_registry][:ports] = [node[:docker_registry][:ports].map { |host, container| "#{host}:#{container}" }]
default[:docker_registry][:volumes] = ["#{node[:docker_registry][:path]}:/docker-registry"]
default[:docker_registry][:env_vars] = ["DOCKER_REGISTRY_CONFIG=/docker-registry/config/config.yml"]

# misc. docker container config
default[:docker_registry][:detach] = true
default[:docker_registry][:tty] = true
default[:docker_registry][:standalone] = true
default[:docker_registry][:publish_exposed_ports] = false
default[:docker_registry][:registry_git_url] = 'https://github.com/dotcloud/docker-registry.git'
default[:docker_registry][:registry_git_ref] = 'master'

# nginx load balancer core config
default[:docker_registry][:nginx][:server_port] = 80
default[:docker_registry][:nginx][:server_url] = node[:docker_registry][:url]
default[:docker_registry][:nginx][:owner] = node[:docker_registry][:user]
default[:docker_registry][:nginx][:group] = node[:docker_registry][:group]

# setup nginx upstream{...} block from docker container 'link' vars
upstream_host_var = "#{node[:docker_registry][:name].upcase}_PORT_#{node[:docker_registry][:port]}_TCP_ADDR"
upstream_port_var = "#{node[:docker_registry][:name].upcase}_PORT_#{node[:docker_registry][:port]}_TCP_PORT"
default[:docker_registry][:nginx][:upstream_host] = ENV[upstream_host_var] || node[:docker_registry][:url]
default[:docker_registry][:nginx][:upstream_port] = ENV[upstream_port_var].to_i || node[:docker_registry][:port]
default[:docker_registry][:nginx][:upstream_socket] = node[:docker_registry][:bind_socket] || nil

# nginx basic_auth & ssl config
default[:docker_registry][:nginx][:auth_greeting] = 'HealthGuru\'s Docker Registry'
default[:docker_registry][:nginx][:auth_users_file] = "/etc/nginx/#{node[:docker_registry][:name]}_passwd"
default[:docker_registry][:nginx][:ssl] = false
default[:docker_registry][:nginx][:ssl_path] = '/etc/ssl'
default[:docker_registry][:nginx][:certificate_path] = nil
default[:docker_registry][:nginx][:certificate_key_path] = nil
default[:docker_registry][:nginx][:set_host_header] = true
