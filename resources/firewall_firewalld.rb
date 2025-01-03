
unified_mode true

# Common properties defined in a resource partial
use '_partial/_firewall'

# firewalld platforms only
provides :firewall, os: 'linux' do |node|
  node['firewall']['solution'] == 'firewalld'
end

action :install do
  firewalld new_resource.name do
    package_options new_resource.package_options if property_is_set?(:package_options)
    action :install
  end
end

action :reload do
  firewalld new_resource.name do
    action :reload
  end
end

action :restart do
  firewalld new_resource.name do
    action :restart
  end
end

action :disable do
  firewalld new_resource.name do
    action :disable
  end
end
