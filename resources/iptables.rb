# frozen_string_literal: true

unified_mode true

use '_partial/_firewall'

provides :iptables,
         os: 'linux'

action :install do
  packages = platform_family?('debian') ? ['iptables-persistent'] : iptables_packages(new_resource)
  packages.each do |pkg|
    package pkg
  end

  iptables_service_names.each do |svc|
    file iptables_rules_path(svc) do
      content '# created by chef to allow service to start'
      action :create_if_missing
    end

    service svc do
      status_command 'true' if svc == 'netfilter-persistent'
      action [:enable, :start]
    end
  end
end

action :rebuild do
  rebuild_iptables
end

action :restart do
  rebuild_iptables
end

action :reload do
  rebuild_iptables
end

action :disable do
  ruby_block "disable iptables #{new_resource.name}" do
    block do
      iptables_flush!(new_resource)
      iptables_default_allow!(new_resource)
    end
  end

  iptables_service_names.each do |svc|
    service svc do
      action [:disable, :stop]
    end

    file iptables_rules_path(svc) do
      content '# created by chef to allow service to start'
    end
  end
end

action :flush do
  ruby_block "flush iptables #{new_resource.name}" do
    block do
      iptables_flush!(new_resource)
    end
  end

  iptables_service_names.each do |svc|
    file iptables_rules_path(svc) do
      content '# created by chef to allow service to start'
    end
  end
end

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Iptables

  def rebuild_iptables
    log_iptables(new_resource)
    ensure_default_rules_exist(new_resource)
    collect_iptables_rules

    iptables_service_names.each do |svc|
      service svc do
        status_command 'true' if svc == 'netfilter-persistent'
        action :nothing
      end

      iptables_rule_files_for_service(svc).each do |iptables_type, rules_path|
        file rules_path do
          content build_rule_file(new_resource.rules[iptables_type])
          notifies :restart, "service[#{svc}]", :immediately
        end
      end
    end
  end

  def collect_iptables_rules
    collect_matching_rules(:iptables_rule).each do |firewall_rule|
      types = if ipv6_rule?(firewall_rule)
                %w(ip6tables)
              elsif ipv4_rule?(firewall_rule)
                %w(iptables)
              else
                %w(iptables ip6tables)
              end

      types.each do |iptables_type|
        next if iptables_type == 'ip6tables' && !new_resource.ipv6_enabled

        rule = build_firewall_rule(node, firewall_rule, iptables_type == 'ip6tables')
        new_resource.rules[iptables_type][rule] = firewall_rule.position
      end
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
    rules << default_firewall_rule('allow loopback', interface: 'lo', protocol: :none) if new_resource.allow_loopback
    rules << default_firewall_rule('allow icmp', protocol: :icmp) if new_resource.allow_icmp
    rules << default_firewall_rule('established', stateful: [:related, :established], protocol: :none) if new_resource.allow_established
    rules << default_firewall_rule('ipv6_icmp', protocol: :'ipv6-icmp') if new_resource.ipv6_enabled && new_resource.allow_established
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

  def iptables_service_names
    return ['netfilter-persistent'] if platform_family?('debian')

    iptables_commands(new_resource)
  end

  def iptables_type_for_service(service_name)
    return 'iptables' if service_name == 'netfilter-persistent'

    service_name
  end

  def iptables_rule_files_for_service(service_name)
    if service_name == 'netfilter-persistent'
      files = { 'iptables' => iptables_rules_path('iptables') }
      files['ip6tables'] = iptables_rules_path('ip6tables') if new_resource.ipv6_enabled
      files
    else
      { iptables_type_for_service(service_name) => iptables_rules_path(service_name) }
    end
  end

  def iptables_rules_path(service_name)
    case service_name
    when 'netfilter-persistent', 'iptables'
      platform_family?('debian') ? '/etc/iptables/rules.v4' : '/etc/sysconfig/iptables'
    when 'ip6tables'
      platform_family?('debian') ? '/etc/iptables/rules.v6' : '/etc/sysconfig/ip6tables'
    else
      raise "Unsupported iptables service #{service_name}"
    end
  end
end
