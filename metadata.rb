name 'firewall'
maintainer 'Chef Software, Inc.'
maintainer_email 'cookbooks@chef.io'
license 'Apache 2.0'
description 'Provides a set of primitives for managing firewalls and associated rules.'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.4.0'

supports 'amazon'
supports 'centos'
supports 'debian'
supports 'fedora'
supports 'oracle'
supports 'redhat'
supports 'scientific'
supports 'ubuntu'

depends 'chef-sugar'

source_url 'https://github.com/chef-cookbooks/firewall' if respond_to?(:source_url)
issues_url 'https://github.com/chef-cookbooks/firewall/issues' if respond_to?(:issues_url)
