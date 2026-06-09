# frozen_string_literal: true

unified_mode true

# Common properties defined in a resource partial
use '_partial/_firewall_rule'
use '_partial/_backend_rule'

provides :firewall_rule

property :log_prefix, String
property :log_group, Integer

action :create do
  firewall_resource = Chef.run_context.resource_collection.find(firewall: new_resource.firewall_name)
  raise 'could not find a firewall resource' unless firewall_resource

  return unless new_resource.notify_firewall

  case firewall_backend(firewall_resource)
  when :firewalld
    create_firewalld_rule
  when :nftables
    create_nftables_rule
  when :iptables
    create_iptables_rule
  when :ufw
    create_ufw_rule
  when :windows
    create_windows_firewall_rule
  else
    raise "Unsupported firewall backend #{firewall_backend(firewall_resource)}"
  end
end

action_class do
  include FirewallCookbook::Helpers

  def firewall_backend(firewall_resource)
    firewall_resource.backend || default_firewall_backend
  end

  def default_firewall_backend
    case node['platform_family']
    when 'debian'
      platform?('debian') ? :nftables : :ufw
    when 'amazon', 'fedora', 'rhel', 'suse'
      :firewalld
    when 'windows'
      :windows
    else
      :iptables
    end
  end

  def create_iptables_rule
    with_run_context :root do
      iptables_rule new_resource.description do
        apply_common_rule_properties(self)
      end
    end
  end

  def create_ufw_rule
    with_run_context :root do
      ufw_rule new_resource.description do
        apply_common_rule_properties(self)
      end
    end
  end

  def create_windows_firewall_rule
    with_run_context :root do
      windows_firewall_rule new_resource.description do
        apply_common_rule_properties(self)
      end
    end
  end

  def create_nftables_rule
    with_run_context :root do
      nftables_rule new_resource.description do
        copy_nftables_rule_properties(self)
        family ipv6_rule?(new_resource) ? :ip6 : :ip
        dport dport_calc(new_resource) if new_resource.property_is_set?(:port) || new_resource.property_is_set?(:dest_port)
      end
    end
  end

  def apply_common_rule_properties(rule)
    copy_rule_properties(rule, common_rule_property_map)
  end

  def copy_nftables_rule_properties(rule)
    copy_rule_properties(rule, nftables_rule_property_map)
  end

  def copy_rule_properties(rule, property_map)
    property_map.each do |source_property, target_property|
      next unless copy_rule_property?(source_property)

      rule.public_send(target_property, new_resource.public_send(source_property))
    end
  end

  def copy_rule_property?(property)
    default_rule_properties.include?(property) || new_resource.property_is_set?(property)
  end

  def default_rule_properties
    [:firewall_name, :command, :protocol, :position, :description, :direction, :include_comment]
  end

  def common_rule_property_map
    {
      firewall_name: :firewall_name,
      command: :command,
      protocol: :protocol,
      source: :source,
      source_port: :source_port,
      port: :port,
      dest_port: :dest_port,
      destination: :destination,
      position: :position,
      description: :description,
      redirect_port: :redirect_port,
      direction: :direction,
      logging: :logging,
      interface: :interface,
      dest_interface: :dest_interface,
      stateful: :stateful,
      include_comment: :include_comment,
      program: :program,
      service: :service,
      raw: :raw,
    }
  end

  def nftables_rule_property_map
    {
      firewall_name: :firewall_name,
      command: :command,
      protocol: :protocol,
      direction: :direction,
      source: :source,
      source_port: :sport,
      interface: :interface,
      destination: :destination,
      dest_interface: :outerface,
      position: :position,
      stateful: :stateful,
      redirect_port: :redirect_port,
      description: :description,
      include_comment: :include_comment,
      log_prefix: :log_prefix,
      log_group: :log_group,
      raw: :raw,
    }
  end

  def create_firewalld_rule
    with_run_context :root do
      firewalld_rule new_resource.description do
        firewall_name new_resource.firewall_name
        command new_resource.command
        protocol new_resource.protocol
        source new_resource.source if new_resource.property_is_set?(:source)
        source_port new_resource.source_port if new_resource.property_is_set?(:source_port)
        port new_resource.port if new_resource.property_is_set?(:port)
        dest_port new_resource.dest_port if new_resource.property_is_set?(:dest_port)
        destination new_resource.destination if new_resource.property_is_set?(:destination)
        position new_resource.position
        description new_resource.description
        redirect_port new_resource.redirect_port if new_resource.property_is_set?(:redirect_port)
        zone new_resource.zone if new_resource.property_is_set?(:zone)
        include_comment new_resource.include_comment
        raw new_resource.raw if new_resource.property_is_set?(:raw)
        notify_firewall new_resource.notify_firewall
      end
    end
  end
end
