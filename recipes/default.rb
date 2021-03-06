#
# Cookbook Name:: docker-registry
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

group node['docker-registry'][:group] do
    gid node['docker-registry'][:gid]
end

user node['docker-registry']['owner'] do
    gid node['docker-registry'][:group]
    home node['docker-registry'][:install_dir]
    shell '/bin/bash'
end

directory node['docker-registry'][:storage_path] do
    mode 0770
    owner node['docker-registry'][:owner]
    group node['docker-registry'][:group]
end
