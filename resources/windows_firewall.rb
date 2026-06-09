# frozen_string_literal: true

unified_mode true

use '_partial/_firewall'

provides :windows_firewall,
         os: 'windows'

action :install do
  service 'MpsSvc' do
    action [:enable, :start]
  end
end

action :rebuild do
  rebuild_windows
end

action :restart do
  rebuild_windows
end

action :reload do
  rebuild_windows
end

action :disable do
  ruby_block "disable windows firewall #{new_resource.name}" do
    block do
      disable! if active?
    end
  end

  service 'MpsSvc' do
    action [:disable, :stop]
  end
end

action :flush do
  ruby_block "reset windows firewall #{new_resource.name}" do
    block do
      reset!
    end
  end
end

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Windows

  def rebuild_windows
    new_resource.rules['windows'] ||= {}
    collect_windows_rules
    policy_rule = "set currentprofile firewallpolicy #{new_resource.windows_policy[:input]},#{new_resource.windows_policy[:output]}"
    new_resource.rules['windows'][policy_rule] ||= 99_999
    sorted_rules = new_resource.rules['windows'].sort_by { |_rule, position| position }.map(&:first)

    ruby_block "apply windows firewall rules #{new_resource.name}" do
      action :nothing
      block do
        disable! if active?
        delete_all_rules!
        reset!
        sorted_rules.each { |cmd| add_rule!(cmd) }
        enable! unless active?
      end
    end

    file windows_rules_filename do
      content build_rule_file(new_resource.rules['windows'])
      notifies :run, "ruby_block[apply windows firewall rules #{new_resource.name}]", :immediately
    end
  end

  def collect_windows_rules
    collect_matching_rules(:windows_firewall_rule).each do |firewall_rule|
      rule = FirewallCookbook::Helpers::Windows.instance_method(:build_rule).bind(self).call(firewall_rule)
      new_resource.rules['windows'][rule] = firewall_rule.position
    end
  end

  def collect_matching_rules(resource_name)
    default_firewall_rules + Chef.run_context.resource_collection.select do |item|
      item.resource_name == resource_name &&
        item.firewall_name == new_resource.name &&
        item.notify_firewall &&
        item.action.include?(:create) &&
        !item.should_skip?(:create)
    end
  end

  def default_firewall_rules
    rules = []
    rules << default_firewall_rule('allow world to winrm', port: 5989) if windows? && new_resource.allow_winrm
    rules
  end

  def default_firewall_rule(name, overrides = {})
    default_firewall_rule_class.new({
      name: name,
      firewall_name: new_resource.name,
      command: :allow,
      protocol: :tcp,
      source: nil,
      source_port: nil,
      port: nil,
      dest_port: nil,
      destination: nil,
      position: 50,
      description: name,
      redirect_port: nil,
      zone: nil,
      direction: :in,
      logging: nil,
      interface: nil,
      dest_interface: nil,
      stateful: nil,
      include_comment: true,
      program: nil,
      service: nil,
      raw: nil,
      notify_firewall: true,
    }.merge(overrides))
  end

  def default_firewall_rule_class
    @default_firewall_rule_class ||= Struct.new(
      :name,
      :firewall_name,
      :command,
      :protocol,
      :source,
      :source_port,
      :port,
      :dest_port,
      :destination,
      :position,
      :description,
      :redirect_port,
      :zone,
      :direction,
      :logging,
      :interface,
      :dest_interface,
      :stateful,
      :include_comment,
      :program,
      :service,
      :raw,
      :notify_firewall,
      keyword_init: true
    )
  end
end
