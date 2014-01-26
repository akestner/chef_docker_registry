name                'docker-registry'
maintainer          'Alex Kestner'
maintainer_email    'akestner@healthguru.com'
license             'Apache 2.0'
description         'Installs and configures docker-registry, with an optional nginx frontend via chef/chef-.'
version             '0.0.5'

recipe  'default', "Installs the docker-registry python application"
recipe  'application', "Installs the docker-registry python application, daemonizing it with gunicorn and using a nginx frontend"

supports 'ubuntu'

depends 'openssl'
depends 'application', '~> 3.0'
depends 'application_nginx'
depends 'application_python'
