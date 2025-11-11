
unified_mode true

default_action :install

property :package_options,
         String,
         description: 'Pass additional options to the package manager when installing the firewall.'
