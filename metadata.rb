name 'firewall'
maintainer 'Opscode, Inc.'
maintainer_email 'cookbooks@opscode.com'
license 'Apache 2.0'
description 'Provides a set of primitives for managing firewalls and associated rules.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '0.13.0'

supports 'ubuntu'
supports 'redhat'
supports 'centos'

depends 'poise', '~> 1.0'
