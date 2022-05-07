unified_mode true

provides :firewalld,
         os: 'linux'

action :install do
  chef_gem 'ruby-dbus'
  require 'dbus'
  package 'firewalld'
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
