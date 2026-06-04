# frozen_string_literal: true

unified_mode true

use '_partial/_firewall'

provides :ufw,
         os: 'linux'

action :install do
  package 'ufw'

  template '/etc/default/ufw' do
    owner 'root'
    group 'root'
    mode '0644'
    source 'ufw/default.erb'
    cookbook 'firewall'
    variables(defaults: new_resource.ufw_defaults)
  end

  file ufw_rules_filename do
    content '# created by chef to allow service to start'
    action :create_if_missing
  end

  service 'ufw' do
    action :enable
  end
end

action :rebuild do
  rebuild_ufw
end

action :restart do
  rebuild_ufw
end

action :reload do
  rebuild_ufw
end

action :disable do
  file ufw_rules_filename do
    content '# created by chef to allow service to start'
  end

  ruby_block "disable ufw #{new_resource.name}" do
    block do
      ufw_disable! if ufw_active?
    end
  end
end

action :flush do
  ruby_block "flush ufw #{new_resource.name}" do
    block do
      ufw_reset!
    end
  end

  file ufw_rules_filename do
    content '# created by chef to allow service to start'
  end
end

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Ufw

  def rebuild_ufw
    new_resource.rules['ufw'] ||= {}
    collect_ufw_rules
    sorted_rules = new_resource.rules['ufw'].sort_by { |_rule, position| position }.map(&:first)

    ruby_block "apply ufw rules #{new_resource.name}" do
      action :nothing
      block do
        ufw_reset!
        ufw_logging!(new_resource.log_level) if new_resource.log_level
        sorted_rules.each { |cmd| ufw_rule!(cmd) }
        ufw_enable! unless ufw_active?
      end
    end

    file ufw_rules_filename do
      content build_rule_file(new_resource.rules['ufw'])
      notifies :run, "ruby_block[apply ufw rules #{new_resource.name}]", :immediately
    end
  end

  def collect_ufw_rules
    collect_matching_rules(:ufw_rule).each do |firewall_rule|
      rule = FirewallCookbook::Helpers::Ufw.instance_method(:build_rule).bind(self).call(firewall_rule)
      new_resource.rules['ufw'][rule] = firewall_rule.position
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
    rules << default_firewall_rule('allow world to ssh', port: 22) if linux? && new_resource.allow_ssh
    rules << default_firewall_rule('allow world to mosh', protocol: :udp, port: 60000..61000) if linux? && new_resource.allow_mosh
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
