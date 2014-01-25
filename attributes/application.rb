#
# Cookbook Name:: docker-registry
# Attributes:: application
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

include 'openssl'

default['docker-registry'][:server_name] = node[:fqdn] || node[:hostname]
default['docker-registry'][:application_name] = 'docker-registry'

default['docker-registry'][:flavor] = 'development'
default['docker-registry'][:session_key] = OpenSSL::Random.base64(64)
default['docker-registry'][:s3_access_key_id] = nil
default['docker-registry'][:s3_secret_access_key] = nil
default['docker-registry'][:standalone] = true
default['docker-registry'][:index_endpoint] = 'https://index.docker.io'

default['docker-registry'][:internal_port] = 5000
default['docker-registry'][:workers] = 8
default['docker-registry'][:max_requests] = 100
default['docker-registry'][:timeout] = 3600
default['docker-registry'][:packages] = ['libevent-dev']

default['docker-registry'][:ssl] = false
default['docker-registry'][:ssl_path] = '/etc/ssl'
default['docker-registry'][:certificate_path] = nil
default['docker-registry'][:certificate_key_path] = nil
