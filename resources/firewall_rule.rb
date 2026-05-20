# frozen_string_literal: true

unified_mode true

# Common properties defined in a resource partial
use '_partial/_firewall_rule'

provides :firewall_rule

property :direction, Symbol, equal_to: [:in, :out, :pre, :post], default: :in
property :logging, Symbol, equal_to: [:connections, :packets]
property :interface, String
property :dest_interface, String
property :stateful, [Symbol, Array]
property :include_comment, [true, false], default: true

# only used for Windows Firewalls
property :program, String
property :service, String

# for when you just want to pass a raw rule
property :raw, String

# do you want this rule to notify the firewall to recalculate
# (and potentially reapply) the firewall_rule(s) it finds?
property :notify_firewall, [true, false], default: true

action :create do
  firewall_resource = Chef.run_context.resource_collection.find(firewall: new_resource.firewall_name)
  raise 'could not find a firewall resource' unless firewall_resource

  return unless new_resource.notify_firewall

  if firewall_solution(firewall_resource) == :firewalld
    create_firewalld_rule
  else
    with_run_context :root do
      edit_resource!(:firewall, new_resource.firewall_name) do
        delayed_action :restart
      end
    end
  end
end

action_class do
  def firewall_solution(firewall_resource)
    return firewall_resource.solution if firewall_resource.solution

    case node['platform_family']
    when 'debian'
      :ufw
    when 'amazon', 'fedora', 'rhel', 'suse'
      :firewalld
    when 'windows'
      :windows
    else
      :iptables
    end
  end

  def create_firewalld_rule
    if property_is_set?(:port) && property_is_set?(:dest_port)
      raise 'The "port" property is a shorthand for "dest_port" and cannot be set together with "dest_port". Please set only one of them.'
    end

    if new_resource.command == :masquerade
      firewalld_rich_rule new_resource.description do
        zone new_resource.zone if new_resource.property_is_set?(:zone)
        masquerade true
      end

      return
    end

    if new_resource.command == :redirect
      firewalld_rich_rule new_resource.description do
        zone new_resource.zone if new_resource.property_is_set?(:zone)
        forward_port new_resource.source_port
        to_port new_resource.redirect_port
        protocol new_resource.protocol.to_s
      end

      return
    end

    array_property = check_for_port_array_property
    if array_property
      new_resource.send(array_property).each do |array_item|
        create_single_firewalld_rule(format_port(array_item), array_property)
      end
    else
      create_single_firewalld_rule(nil, nil)
    end
  end

  def create_single_firewalld_rule(array_item, array_property)
    rule_name = array_item ? "#{new_resource.description} [#{array_item}/#{new_resource.protocol}]" : new_resource.description

    firewalld_rich_rule rule_name do
      zone new_resource.zone if new_resource.property_is_set?(:zone)
      source new_resource.source if new_resource.property_is_set?(:source)
      destination new_resource.destination if new_resource.property_is_set?(:destination)
      priority new_resource.position if new_resource.property_is_set?(:position)

      if array_property == :source_port
        source_port array_item
        port new_resource.port if new_resource.property_is_set?(:port)
        port new_resource.dest_port if new_resource.property_is_set?(:dest_port)
      elsif [:port, :dest_port].include?(array_property)
        port array_item
        source_port new_resource.source_port if new_resource.property_is_set?(:source_port)
      else
        source_port format_port(new_resource.source_port) if new_resource.property_is_set?(:source_port)
        port format_port(new_resource.port) if new_resource.property_is_set?(:port)
        port format_port(new_resource.dest_port) if new_resource.property_is_set?(:dest_port)
      end

      protocol new_resource.protocol.to_s if firewalld_protocol_required?
      rule_action firewalld_action_map[new_resource.command] if firewalld_action_map.key?(new_resource.command)
      log true if new_resource.command == :log
      action :add
    end
  end

  def check_for_port_array_property
    array_properties = [:source_port, :port, :dest_port].select do |property|
      new_resource.property_is_set?(property) && new_resource.send(property).is_a?(Array)
    end

    if array_properties.size > 1
      raise 'Only one of source_port, port, or dest_port can be an Array at a time.'
    end

    array_properties.first
  end

  def firewalld_action_map
    {
      reject: :reject,
      allow: :accept,
      deny: :drop,
    }
  end

  def firewalld_protocol_required?
    property_is_set?(:protocol) || property_is_set?(:port) ||
      property_is_set?(:dest_port) || property_is_set?(:source_port)
  end

  def format_port(value)
    value.is_a?(Range) ? "#{value.min}-#{value.max}" : value
  end
end
