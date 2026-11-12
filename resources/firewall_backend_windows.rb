# frozen_string_literal: true

provides :firewall_backend_windows
unified_mode true
use '_partial/_firewall'

action :install do
  service 'MpsSvc' do
    action %i(enable start)
  end
end

action :restart do
  desired = (new_resource.rules['windows'] || {}).dup
  new_resource.rule_resources.each { |rule| desired[build_rule(rule)] = rule.position }
  desired["set currentprofile firewallpolicy #{new_resource.windows_input_policy},#{new_resource.windows_output_policy}"] = 99_999
  contents = build_rule_file(desired)
  ruby_block "apply #{new_resource.name} Windows firewall rules" do
    block do
      disable! if active?
      delete_all_rules!
      reset!
      desired.sort_by { |_rule, position| position }.each { |rule, _position| add_rule!(rule) }
      enable!
    end
    only_if { !::File.exist?(windows_rules_filename) || ::File.read(windows_rules_filename) != contents || !active? }
  end
  file windows_rules_filename do
    content contents
  end
end

action :disable do
  execute 'disable Windows firewall' do
    command 'netsh advfirewall set currentprofile state off'
    only_if { active? }
  end
end

action :flush do
  execute 'reset Windows firewall' do
    command 'netsh advfirewall reset'
  end
  file windows_rules_filename do
    action :delete
  end
end

action :delete do
  execute 'remove managed Windows firewall configuration' do
    command 'netsh advfirewall reset'
    only_if { ::File.exist?(windows_rules_filename) }
  end
  file windows_rules_filename do
    action :delete
  end
end

action :save do
  raise ArgumentError, ':save is only supported by the firewalld backend'
end

action_class do
  include FirewallCookbook::Helpers::Windows
end
