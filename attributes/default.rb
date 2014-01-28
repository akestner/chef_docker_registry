#
# Cookbook Name:: docker-registry
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

node.default['docker-registry'][:flavor] = 'development'
node.default['docker-registry'][:storage] = 's3'
node.default['docker-registry'][:storage_path] = "registry/#{(node.chef_environment || 'development')}"
node.default['docker-registry'][:secret_key] = nil
node.default['docker-registry'][:s3_access_key_id] = nil
node.default['docker-registry'][:s3_secret_access_key] = nil
node.default['docker-registry'][:standalone] = true
node.default['docker-registry'][:index_endpoint] = 'https://index.docker.io'

node.default['docker-registry'][:application][:name] = 'docker-registry'
node.default['docker-registry'][:application][:owner] = 'docker-registry'
node.default['docker-registry'][:application][:group] = 'docker-registry'
node.default['docker-registry'][:application][:install_dir] = '/opt/docker-registry'
node.default['docker-registry'][:application][:repository] = 'https://github.com/dotcloud/docker-registry.git'
node.default['docker-registry'][:application][:revision] = '0.6.5'
node.default['docker-registry'][:application][:packages] = ['libevent-dev']
node.default['docker-registry'][:application][:server_role] = "#{node['docker-registry'][:application][:name]}_application_python"
node.default['docker-registry'][:application][:load_balancer_role] = "#{node['docker-registry'][:application][:name]}_application_nginx"

node.default['docker-registry'][:gunicorn][:virtualenv_name] = node['docker-registry'][:application][:name]
node.default['docker-registry'][:gunicorn][:internal_port] = 5000
node.default['docker-registry'][:gunicorn][:app_module] = 'wsgi:application'
node.default['docker-registry'][:gunicorn][:workers] = 8
node.default['docker-registry'][:gunicorn][:worker_class] = 'gevent'
node.default['docker-registry'][:gunicorn][:max_requests] = 100
node.default['docker-registry'][:gunicorn][:timeout] = 3600
node.default['docker-registry'][:gunicorn][:working_dir] = "#{node['docker-registry'][:application][:install_dir]}/current"
node.default['docker-registry'][:gunicorn][:log_file] = '-'
node.default['docker-registry'][:gunicorn][:log_level] = :info
node.default['docker-registry'][:gunicorn][:debug] = false
node.default['docker-registry'][:gunicorn][:trace] = false

node.default['docker-registry'][:nginx][:server_name] = 'localhost'
node.default['docker-registry'][:nginx][:port] = 8080
node.default['docker-registry'][:nginx][:hosts] = ['127.0.0.1']
node.default['docker-registry'][:nginx][:application_socket] =
node.default['docker-registry'][:nginx][:ssl] = false
node.default['docker-registry'][:nginx][:ssl_path] = '/etc/ssl'
node.default['docker-registry'][:nginx][:certificate_path] = nil
node.default['docker-registry'][:nginx][:certificate_key_path] = nil
node.default['docker-registry'][:nginx][:set_host_header] = true

