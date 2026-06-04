# frozen_string_literal: true

unified_mode true

use '_partial/_firewall_rule'

provides :firewalld_rule,
         os: 'linux'

property :family, Symbol, equal_to: [:ipv4, :ipv6]
property :include_comment, [true, false], default: true
property :raw, String
property :notify_firewall, [true, false], default: true

action :create do
  return unless new_resource.notify_firewall

  create_firewalld_rule
end

action_class do
  include FirewallCookbook::Helpers

  def create_firewalld_rule
    if property_is_set?(:port) && property_is_set?(:dest_port)
      raise 'The "port" property is a shorthand for "dest_port" and cannot be set together with "dest_port". Please set only one of them.'
    end

    if new_resource.command == :masquerade
      firewalld_rich_rule new_resource.description do
        raw new_resource.raw if new_resource.property_is_set?(:raw)
        zone new_resource.zone if new_resource.property_is_set?(:zone)
        family new_resource.family if new_resource.property_is_set?(:family)
        masquerade true unless new_resource.property_is_set?(:raw)
      end

      return
    end

    if new_resource.command == :redirect
      firewalld_rich_rule new_resource.description do
        raw new_resource.raw if new_resource.property_is_set?(:raw)
        zone new_resource.zone if new_resource.property_is_set?(:zone)
        family new_resource.family if new_resource.property_is_set?(:family)
        forward_port new_resource.source_port unless new_resource.property_is_set?(:raw)
        to_port new_resource.redirect_port unless new_resource.property_is_set?(:raw)
        protocol new_resource.protocol.to_s unless new_resource.property_is_set?(:raw)
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
      raw new_resource.raw if new_resource.property_is_set?(:raw)
      zone new_resource.zone if new_resource.property_is_set?(:zone)
      family new_resource.family if new_resource.property_is_set?(:family)
      source new_resource.source if new_resource.property_is_set?(:source)
      destination new_resource.destination if new_resource.property_is_set?(:destination)
      priority new_resource.position unless default_position?

      unless new_resource.property_is_set?(:raw)
        if array_property == :source_port
          source_port array_item
          port format_port(new_resource.port) if new_resource.property_is_set?(:port)
          port format_port(new_resource.dest_port) if new_resource.property_is_set?(:dest_port)
        elsif [:port, :dest_port].include?(array_property)
          port array_item
          source_port format_port(new_resource.source_port) if new_resource.property_is_set?(:source_port)
        else
          source_port format_port(new_resource.source_port) if new_resource.property_is_set?(:source_port)
          port format_port(new_resource.port) if new_resource.property_is_set?(:port)
          port format_port(new_resource.dest_port) if new_resource.property_is_set?(:dest_port)
        end

        protocol new_resource.protocol.to_s if firewalld_protocol_required?
        rule_action firewalld_action_map[new_resource.command] if firewalld_action_map.key?(new_resource.command)
        log true if new_resource.command == :log
      end

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
    new_resource.protocol != :tcp || property_is_set?(:port) ||
      property_is_set?(:dest_port) || property_is_set?(:source_port)
  end

  def default_position?
    new_resource.position == 50
  end

  def format_port(value)
    value.is_a?(Range) ? "#{value.min}-#{value.max}" : value
  end
end
