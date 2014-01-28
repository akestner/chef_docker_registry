Description
===========

This cookbook deploys the dotCloud [docker-registry](https://github.com/dotcloud/docker-registry)

Requirements
============

Chef 0.11.0 or higher required (for Chef environment use).

Cookbooks
---------

* chef-docker

Attributes
==========

See `attributes/default.rb` for default values.

* `node[:docker_registry]["revision"]` - Git tag to install.
* `node[:docker_registry]["storage"]` - Defines the type of storage to use, local or s3.
* `node[:docker_registry]["ssl"]` - If ssl should be enabled.
* `node[:docker_registry]["server_name"]` - The FQDN that NGiNX will proxy for.
* `node[:docker_registry]["data_bag"]` - Name of data bag containing encrypted secrets.
* `node[:docker_registry]["s3_access_key"]` - Your S3 Access Key.
* `node[:docker_registry]["s3_bucket"]` - Your S3 storage bucket.
* `node[:docker_registry]["secret_key"]` - A 64 character random string. This is used to secure the session cookie. It is recommended to store this in the encrypted data bag.

Data Bag
==========

To enable SSL or use S3 as a storage backend a data bag must be created to store the secrets. The data bag should contain an item for each environment that will host the `:docker_registry`.

    $ knife data bag show BAG_NAME ENVIRONMENT --secret-file=my-secret-file
    {
      "id": "ENVIRONMENT",
      "secret_key": "...",
      "ssl_certificate": [
        "....", # SSL Certificate Chain
        "....",
        "...." 
      ],
      "ssl_certificate_key": "...",
      "s3_secret_key": "..."
    }

The `ssl_certificate` should contain the entire Certificate chain starting with the server certificate. The values should not contain any new lines. You can do this with `cat my_cert.crt | tr -d '\r\n'`.
