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

# setup users/groups, permissions
if node[:docker_registry][:user] != 'root'
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

    public_key_dir = "/home/#{node[:docker_registry][:user]}/.ssh"
else
    public_key_dir = ::File.join(node[:docker_registry][:user], '.ssh').to_s
end

# make sure local storage path is created
if node[:docker_registry][:storage] == 'local'
    directory node[:docker_registry][:storage_path] do
        owner node[:docker_registry][:user]
        group node[:docker_registry][:group]
        recursive true
        mode 0776
        action :create
        not_if { ::File.directory?(dir) }
    end
end

directory node[:docker_registry][:nginx][:config_dir] do
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    recursive true
    mode 0755
    action :create
    not_if { ::File.directory?(node[:docker_registry][:nginx][:config_dir]) }
end

path_parent_dir = ::File.dirname(node[:docker_registry][:path]).to_s
directory path_parent_dir do
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    recursive true
    mode 0766
    action :create
    not_if { ::File.directory?(path_parent_dir) }
end

# clone dotcloud/docker-registry source
git node[:docker_registry][:path] do
    repository node[:docker_registry][:git_source_url]
    reference node[:docker_registry][:git_source_ref]
    user node[:docker_registry][:user]
    group node[:docker_registry][:group]
    action :sync
end

# decrypt our data_bag
data_bag = DockerRegistry.decrypt_data_bag(
    node[:docker_registry][:data_bag],
    node[:docker_registry][:data_bag_item],
    ::Chef::Config[:encrypted_data_bag_secret]
)

# expand etc_nginx_passwd.erb template
template node[:docker_registry][:nginx][:auth_users_file] do
    source node[:docker_registry][:nginx][:auth_users_template]
    mode 0755
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    variables({
        :users => data_bag[:registry_users]
    })
end

directory public_key_dir do
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    recursive true
    mode 0700
    action :create
    not_if { ::File.directory?(public_key_dir) }
end

privileged_key_public = ::File.join(public_key_dir, 'healthguru.docker_registry.public.pem').to_s

# template privileged_key_public
template privileged_key_public do
    source 'privileged_key_public.erb'
    mode 0600
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    variables({
        :privileged_key_public => data_bag[:privileged_key_public]
    })
end

# expand docker-registry config.yaml template
template "#{node[:docker_registry][:path]}/config/config.yml" do
    source 'registry_config.yml.erb'
    mode 0440
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    variables({
        :secret_key => data_bag[:secret_key],
        #:privileged_key_public => privileged_key_public,
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

# expand Dockerfile.erb template
template "#{node[:docker_registry][:path]}/Dockerfile" do
    source node[:docker_registry][:dockerfile_template]
    mode 0755
    owner node[:docker_registry][:user]
    group node[:docker_registry][:group]
    variables({
        :port => node[:docker_registry][:port]
    })
end

if node[:docker_registry][:build_registry]
    # build our image
    docker_image node[:docker_registry][:name] do
        source node[:docker_registry][:path]
        rm true
        action :build
    end

    # export it to a tarball, just for a moment
    export_path = ::File.join(node[:docker_registry][:path], '..', "#{node[:docker_registry][:name]}.tgz").to_s
    docker_image node[:docker_registry][:name] do
        destination export_path
        action :save
    end
end

# run our private docker registry,
# either from existing private registry or from the container we just built
docker_container node[:docker_registry][:container_name] do
    container_name node[:docker_registry][:name]
    repository node[:docker_registry][:repository]
    user node[:docker_registry][:user]
    hostname node[:docker_registry][:url]

    init_type node[:docker_registry][:init_type]
    init_template node[:docker_registry][:init_template]

    port node[:docker_registry][:ports]
    env node[:docker_registry][:env_vars]
    volume node[:docker_registry][:volumes]

    detach node[:docker_registry][:detach]
    publish_exposed_ports node[:docker_registry][:publish_exposed_ports]
    tty node[:docker_registry][:tty]

    action :run
end

if node[:docker_registry][:build_registry]
    # import our previously exported tarball
    docker_image node[:docker_registry][:name] do
        repository node[:docker_registry][:repository]
        #noinspection RubyScope
        source export_path
        action :import
    end

    # register with new registry
    docker_registry node[:docker_registry][:registry] do
        username 'healthguru'
        password data_bag[:registry_users][:healthguru]
        email 'accounts@healthguru.com'
    end

    # tag our image into the new repo
    bumped_version = node[:docker_registry][:container_tag].sub(/(\d+).(\d+).(\d+)/) { |match| "#{$1}.#{$2}.#{$3.to_i + 1}" }
    docker_image node[:docker_registry][:name] do
        registry node[:docker_registry][:registry]
        tag bumped_version
        action :tag
    end

    # push our image up to registry
    docker_image node[:docker_registry][:name] do
        repository node[:docker_registry][:repository]
        action :push
    end
else
    # login to the private registry
    docker_registry node[:docker_registry][:registry] do
        username 'healthguru'
        password data_bag[:registry_users][:healthguru]
    end
end
