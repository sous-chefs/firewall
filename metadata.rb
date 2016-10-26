name 'firewall'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache 2.0'
description 'Provides a set of primitives for managing firewalls and associated rules.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.5.3'

supports 'amazon'
supports 'centos'
supports 'debian'
supports 'fedora'
supports 'oracle'
supports 'redhat'
supports 'scientific'
supports 'ubuntu'
supports 'windows'

depends 'chef-sugar'

source_url 'https://github.com/chef-cookbooks/firewall'
issues_url 'https://github.com/chef-cookbooks/firewall/issues'
chef_version '>= 12.4' if respond_to?(:chef_version)
