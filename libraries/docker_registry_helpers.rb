module DockerRegistry
    module DataBag
        def decrypt_data_bag(data_bag, data_bag_item, data_bag_secret)
            data_bag ||= node['docker-registry'][:data_bag]
            data_bag_item ||= node['docker-registry'][:data_bag_item] || node.chef_environment

            @data_bag_secret ||= Chef::EncryptedDataBagItem.load_secret(
                (data_bag_secret || Chef::Config[:encrypted_data_bag_secret])
            )

            @data_bag_item = Chef::EncryptedDataBagItem.load(data_bag, data_bag_item, @data_bag_secret)
        end

        def ssl_certificate(data_bag, data_bag_item, data_bag_secret)
            if node['docker-registry'][:ssl]

                unless @data_bag_item.nil?
                    @data_bag_secret ||= Chef::EncryptedDataBagItem.load_secret(
                        (data_bag_secret || Chef::Config[:encrypted_data_bag_secret])
                    )
                    self.decrypt_data_bag data_bag, data_bag_item, @data_bag_secret
                end

                if !@data_bag_item[:ssl_certificate].nil? && !@data_bag_item[:ssl_certificate_key].nil?
                    certificate_path = ::File.join(node['docker-registry'][:ssl_path], 'certs', 'docker-registry.crt')

                    template certificate_path do
                        source 'certificate.crt.erb'
                        mode 0444
                        owner 'root'
                        owner 'root'

                        unless @data_bag_item[:ssl_certificate].is_a?(Array)
                            @data_bag_item[:ssl_certificate] = [@data_bag_item[:ssl_certificate]]
                        end

                        variables({
                            :certificates => @data_bag_item[:ssl_certificate]
                        })
                    end

                    certificate_key_path = ::File.join(
                        node['docker-registry'][:ssl_path], 'private', 'docker-registry.key'
                    )

                    template certificate_key_path do
                        source 'certificate.key.erb'
                        mode 0440
                        owner 'root'
                        group 'root'
                        variables({
                            :key => @data_bag_item[:ssl_certificate_key]
                        })
                    end

                    certificate = { :path => certificate_path, :key_path => certificate_key_path }
                end
            end
        end

    end
end