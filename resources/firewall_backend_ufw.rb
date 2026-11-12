# frozen_string_literal: true

provides :firewall_backend_ufw
unified_mode true
use '_partial/_firewall'

action :install do
  package 'ufw' do
    options new_resource.package_options if new_resource.package_options
  end
  template '/etc/default/ufw' do
    source 'ufw/default.erb'
    cookbook 'firewall'
    variables(defaults: new_resource.ufw_defaults.merge(ipv6: new_resource.ipv6_enabled ? 'yes' : 'no'))
    mode '0644'
  end
  file ufw_rules_filename do
    content '# created by chef to allow service to start'
    action :create_if_missing
  end
end

action :restart do
  desired = (new_resource.rules['ufw'] || {}).dup
  new_resource.rule_resources.each { |rule| desired[build_rule(rule)] = rule.position }
  contents = "# logging=#{new_resource.log_level} ipv6=#{new_resource.ipv6_enabled} defaults=#{new_resource.ufw_defaults.inspect}\n#{build_rule_file(desired)}"
  ruby_block "apply #{new_resource.name} ufw rules" do
    block do
      ufw_reset!
      ufw_logging!(new_resource.log_level)
      desired.sort_by { |_rule, position| position }.each { |rule, _position| ufw_rule!(rule) }
      ufw_enable! unless ufw_active?
    end
    only_if { !::File.exist?(ufw_rules_filename) || ::File.read(ufw_rules_filename) != contents || !ufw_active? }
  end
  file ufw_rules_filename do
    content contents
    mode '0600'
  end
end

action :disable do
  execute 'disable ufw' do
    command ['ufw', '--force', 'disable']
    only_if { ufw_active? }
  end
  file ufw_rules_filename do
    content '# created by chef to allow service to start'
  end
end

action :flush do
  execute 'reset ufw' do
    command ['ufw', '--force', 'reset']
  end
  file ufw_rules_filename do
    content '# created by chef to allow service to start'
  end
end

action :delete do
  execute 'disable ufw before removal' do
    command ['ufw', '--force', 'disable']
    only_if { ::File.exist?('/usr/sbin/ufw') && ufw_active? }
  end
  [ufw_rules_filename, '/etc/default/ufw'].each do |path|
    file path do
      action :delete
    end
  end
  package 'ufw' do
    action :remove
  end
end

action :save do
  raise ArgumentError, ':save is only supported by the firewalld backend'
end

action_class do
  include FirewallCookbook::Helpers::Ufw
end
