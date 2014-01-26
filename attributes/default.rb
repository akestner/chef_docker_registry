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

default['docker-registry'][:repository] = 'https://github.com/dotcloud/docker-registry.git'
default['docker-registry'][:tag] = '0.6.5'
default['docker-registry'][:owner] = 'docker-registry'
default['docker-registry'][:group] = 'docker-registry'
default['docker-registry'][:install_dir] = '/usr/local/opt/docker-registry'

default['docker-registry'][:storage] = 'local'
default['docker-registry'][:storage_path] = '/var/lib/docker-registry'
