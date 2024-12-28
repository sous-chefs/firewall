unified_mode true

provides :firewalld,
         os: 'linux'

# Custom options to pass to the package manager during install of firewalld package
property :package_options, String

action :install do
  chef_gem 'ruby-dbus'
  require 'dbus'

  package 'firewalld' do
    options new_resource.package_options if new_resource.package_options
    action :install
  end

  service 'firewalld' do
    action [:enable, :start]
  end
end

action :reload do
  service 'firewalld' do
    action :reload
  end
end

action :restart do
  service 'firewalld' do
    action :restart
  end
end

action :disable do
  service 'firewalld' do
    action [:disable, :stop]
  end
end
