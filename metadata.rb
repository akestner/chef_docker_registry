name                'docker-registry'
maintainer          'Alex Kestner'
maintainer_email    'akestner@healthguru.com'
license             'Apache 2.0'
description         'Installs and configures docker-registry, with an optional nginx frontend via chef/chef-.'
version             '0.0.5'

supports 'ubuntu'

depends 'application', '~> 3.0'
depends 'openssl'
