# frozen_string_literal: true

provides :firewall_rule_firewalld
unified_mode true
use '_partial/_firewall_rule'
property :zone, String

%i(create delete).each do |operation|
  action operation do
    if property_is_set?(:port) && property_is_set?(:dest_port)
      raise ArgumentError, 'Set either port or dest_port, not both'
    end
    arrays = %i(source_port port dest_port).select do |property|
      new_resource.property_is_set?(property) && new_resource.public_send(property).is_a?(Array)
    end
    raise ArgumentError, 'Only one of source_port, port, or dest_port can be an Array' if arrays.length > 1

    parent = new_resource
    variants = arrays.empty? ? [nil] : parent.public_send(arrays.first)
    variants.each do |item|
      properties = {}
      %i(zone source destination).each do |property|
        properties[property] = parent.public_send(property) if parent.property_is_set?(property)
      end
      properties[:priority] = parent.position if parent.property_is_set?(:position)
      %i(source_port port dest_port).each do |property|
        next unless parent.property_is_set?(property)
        value = property == arrays.first ? item : parent.public_send(property)
        properties[property == :dest_port ? :port : property] = value.is_a?(Range) ? "#{value.min}-#{value.max}" : value
      end
      if parent.command == :masquerade
        properties[:masquerade] = true
      elsif parent.command == :redirect
        properties[:forward_port] = properties.delete(:port) || properties.delete(:source_port)
        properties[:to_port] = parent.redirect_port
        properties[:protocol] = parent.protocol.to_s
      else
        properties[:protocol] = parent.protocol.to_s if parent.protocol != :none && (parent.property_is_set?(:protocol) || %i(port dest_port source_port).any? { |property| parent.property_is_set?(property) })
        properties[:rule_action] = { allow: :accept, deny: :drop, reject: :reject }[parent.command] unless parent.command == :log
        properties[:log] = true if parent.command == :log
      end
      name = item.nil? ? parent.description : "#{parent.description} [#{item}/#{parent.protocol}]"
      firewalld_rich_rule name do
        properties.each { |property, value| public_send(property, value) }
        action(operation == :create ? :add : :remove)
      end
    end
  end
end
