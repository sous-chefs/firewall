unified_mode true

provides :firewalld,
         os: 'linux'

action :install do
  chef_gem 'ruby-dbus'
  require 'dbus'

  package 'firewalld' do
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
