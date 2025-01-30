
unified_mode true

# Common properties defined in a resource partial
use '_partial/_firewall_rule'

# firewalld platforms only
provides :firewall_rule, os: 'linux' do |node|
  node['firewall']['solution'] == 'firewalld'
end

# Additional firewalld-only properties
property :zone,
         String,
         description: "Zone in which to apply the rule. If not specified, the rule will be applied to the systems's default zone."

action :create do
  if property_is_set?(:port) && property_is_set?(:dest_port)
    raise 'The "port" property is a shorthand for "dest_port" and cannot be set together with "dest_port". Please set only one of them.'
  end

  if new_resource.command == :masquerade
    firewalld_rich_rule new_resource.description do
      masquerade true
    end

    return
  end

  if new_resource.command == :redirect
    # An iptables REDIRECT is just a DNAT shorthand to the IP of the incoming
    # interface, i.e. the destination address is implied
    firewalld_rich_rule new_resource.description do
      forward_port new_resource.source_port
      to_port new_resource.redirect_port
      protocol new_resource.protocol.to_s
    end

    return
  end

  rule_action_map = {
    reject: :reject,
    allow: :accept,
    deny: :drop,
  }

  protocol_required = property_is_set?(:protocol) || property_is_set?(:port) | property_is_set?(:dest_port) | property_is_set?(:source_port)
  array_property = check_for_port_array_property(new_resource)

  if array_property
    # firewalld doesn't support port arrays, so we must loop over the array
    # items in order to create distinct rules for each port in the array.

    new_resource.send(array_property).each do |array_item|
      array_item = format_port(array_item)

      firewalld_rich_rule "#{new_resource.description} [#{array_item}/#{new_resource.protocol}]" do
        if [:source_port].include?(array_property)
          source_port array_item
          port new_resource.port if new_resource.property_is_set?(:port) # Shorthand, same as :dest_port
          port new_resource.dest_port if new_resource.property_is_set?(:dest_port)
        elsif [:port, :dest_port].include?(array_property)
          port array_item
          source_port new_resource.source_port if new_resource.property_is_set?(:source_port)
        end

        # The rest of the properties as usual
        zone new_resource.zone                            if new_resource.property_is_set?(:zone)
        source new_resource.source                        if new_resource.property_is_set?(:source)
        protocol new_resource.protocol.to_s               if protocol_required
        destination new_resource.destination              if new_resource.property_is_set?(:destination)
        priority new_resource.position                    if new_resource.property_is_set?(:position)
        rule_action rule_action_map[new_resource.command] if rule_action_map.keys.include?(new_resource.command)
        log true                                          if new_resource.command == :log
        action :add
      end
    end

    return
  end

  firewalld_rich_rule new_resource.description do
    zone new_resource.zone                            if new_resource.property_is_set?(:zone)
    source new_resource.source                        if new_resource.property_is_set?(:source)
    source_port format_port(new_resource.source_port) if new_resource.property_is_set?(:source_port)
    port format_port(new_resource.port)               if new_resource.property_is_set?(:port) # Shorthand, same as :dest_port
    port format_port(new_resource.dest_port)          if new_resource.property_is_set?(:dest_port)
    protocol new_resource.protocol.to_s               if protocol_required
    destination new_resource.destination              if new_resource.property_is_set?(:destination)
    priority new_resource.position                    if new_resource.property_is_set?(:position)
    rule_action rule_action_map[new_resource.command] if rule_action_map.keys.include?(new_resource.command)
    log true                                          if new_resource.command == :log
    action :add
  end
end

action_class do
  def check_for_port_array_property(new_resource)
    array_properties = [:source_port, :port, :dest_port].select do |property|
      new_resource.property_is_set?(property) && new_resource.send(property).is_a?(Array)
    end

    if array_properties.size > 1
      raise 'Only one of source_port, port, or dest_port can be an Array at a time.'
    end

    array_properties.first # Return the property that is an Array
  end

  def format_port(value)
    # Convert the Ruby range to a firewalld port range, e.g. "1-100"
    value.is_a?(Range) ? "#{value.min}-#{value.max}" : value
  end
end
