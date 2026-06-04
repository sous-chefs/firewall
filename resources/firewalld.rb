# frozen_string_literal: true

unified_mode true

provides :firewalld,
         os: 'linux'

# Custom options to pass to the package manager during install of firewalld package
property :package_options, String
property :allow_ssh, [true, false], default: false
property :allow_mosh, [true, false], default: false

action :install do
  chef_gem 'ruby-dbus'

  package 'firewalld' do
    options new_resource.package_options if new_resource.package_options
    action :install
  end

  service 'firewalld' do
    action [:enable, :start]
  end

  declare_default_rules
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

action :flush do
  service 'firewalld' do
    action :reload
  end
end

action_class do
  def declare_default_rules
    if linux? && new_resource.allow_ssh
      firewalld_rule 'allow world to ssh' do
        family :ipv4
        source '0.0.0.0/0'
        port 22
        protocol :tcp
        command :allow
      end
    end

    if linux? && new_resource.allow_mosh
      firewalld_rule 'allow world to mosh' do
        family :ipv4
        source '0.0.0.0/0'
        port 60000..61000
        protocol :udp
        command :allow
      end
    end
  end
end
