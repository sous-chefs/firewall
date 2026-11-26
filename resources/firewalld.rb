# frozen_string_literal: true

unified_mode true

provides :firewalld,
         os: 'linux'

property :dbus_gem_version, String, default: '0.25.0'
property :package_options, String

action :install do
  chef_gem 'ruby-dbus' do
    version new_resource.dbus_gem_version
    compile_time false
  end
  require 'dbus'
  service 'dbus' do
    action :nothing
  end
  package 'firewalld' do
    options new_resource.package_options if new_resource.package_options
    notifies :reload, 'service[dbus]', :immediately
  end
  systemd_unit 'firewalld.service' do
    action [:enable, :start]
  end
  execute 'wait for firewalld D-Bus API' do
    command %w(firewall-cmd --state)
    retries 30
    retry_delay 1
    not_if 'firewall-cmd --state'
  end
end

action :reload do
  systemd_unit 'firewalld.service' do
    action :reload
  end
end

action :restart do
  systemd_unit 'firewalld.service' do
    action :restart
  end
  execute 'wait for restarted firewalld D-Bus API' do
    command %w(firewall-cmd --state)
    retries 30
    retry_delay 1
    not_if 'firewall-cmd --state'
  end
end

action :disable do
  systemd_unit 'firewalld.service' do
    action [:disable, :stop]
  end
end

action :delete do
  systemd_unit 'firewalld.service' do
    action [:disable, :stop]
  end
  package 'firewalld' do
    options '--setopt=clean_requirements_on_remove=False' if platform_family?('rhel', 'fedora', 'amazon')
    action :remove
  end
end
