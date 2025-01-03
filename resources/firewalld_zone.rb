unified_mode true

provides :firewalld_zone,
         os: 'linux'

property :description,
         String,
         description: 'see description tag in firewalld.zone(5).'
property :egress_priority,
         [Integer],
         description: 'set the zone priority for egress traffic. A lower priority value has higher precedence. Added in firewalld 2.0.0. See https://firewalld.org/2023/04/zone-priorities for more information.'
property :forward,
         [true, false],
         description: 'see forward tag in firewalld.zone(5).'
property :forward_ports,
         [Array, String],
         description: 'array of (port, protocol, to-port, to-addr). See forward-port tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :icmp_block_inversion,
         [true, false],
         description: 'see icmp-block-inversion tag in firewalld.zone(5).'
property :icmp_blocks,
         [Array, String],
         description: 'array of icmp-blocks. See icmp-block tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :ingress_priority,
         [Integer],
         description: 'set the zone priority for ingress traffic. A lower priority value has higher precedence. Added in firewalld 2.0.0. See https://firewalld.org/2023/04/zone-priorities for more information.'
property :interfaces,
         [Array, String],
         description: 'array of interfaces. See interface tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :masquerade,
         [true, false],
         description: 'see masquerade tag in firewalld.zone(5).'
property :ports,
         [Array, String],
         description: 'array of port and protocol pairs, in `["PORT/PROTOCOL"]` format. See port tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :priority,
         [Integer],
         description: 'set the zone priority for both ingress and egress traffic. A lower priority value has higher precedence. Added in firewalld 2.0.0. See https://firewalld.org/2023/04/zone-priorities for more information.'
property :protocols,
         [Array, String],
         description: 'array of protocols, see protocol tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :rules_str,
         [Array, String],
         description: 'array of rich-language rules. See rule tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :services,
         [Array, String],
         description: 'array of service names, see service tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :short,
         String,
         name_property: true,
         description: 'see short tag in firewalld.zone(5).'
property :source_ports,
         [Array, String],
         description: 'array of port and protocol pairs, in `["PORT/PROTOCOL"]` format. See source-port tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :sources,
         [Array, String],
         description: 'array of source addresses. See source tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :target,
         String,
         description: 'see target attribute of zone tag in firewalld.zone(5).'
property :version,
         String,
         description: 'see version attribute of zone tag in firewalld.zone(5).'

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  fw_config = firewalld_object['org.fedoraproject.FirewallD1.config']
  if fw_config.getZoneNames.include?(new_resource.short)
    zone_path = fw_config.getZoneByName(new_resource.short)
    object = firewalld_service[zone_path]
    config_zone = object['org.fedoraproject.FirewallD1.config.zone']
    config_zone.getSettings2.each do |k, v|
      # Load the current value of ports in the same format as the resource property to make it idempotent
      v = v.map { |port, protocol| "#{port}/#{protocol}" } if %w(ports source_ports).include?(k)
      send(k, v)
    end
  else
    Chef::Log.info "Zone #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)

  unless fw_config.getZoneNames.include?(new_resource.short)
    # Need to explicity disable "forward" when creating a zone via DBus
    # Due to https://github.com/firewalld/firewalld/issues/1438
    zone_settings = { 'forward' => false }
    fw_config.addZone2(new_resource.short, zone_settings)
  end
  zone_path = fw_config.getZoneByName(new_resource.short)
  zone = zone_interface(dbus, zone_path)

  if property_is_set?(:priority) && (property_is_set?(:ingress_priority) || property_is_set?(:egress_priority))
    raise 'The "priority" property cannot be used together with "ingress_priority" or "egress_priority". ' \
          'You may either specify "priority" alone or one/both of "ingress_priority" and "egress_priority", ' \
          'but not both types together.'
  end

  reload = false
  properties = new_resource.class.state_properties.map(&:name)
  properties.each do |property|
    if [:ingress_priority, :egress_priority].include?(property) && property_is_set?(:priority)
      new_resource.send("#{property}=", new_resource.priority)
    end
    next if property == :priority # Shorthand property that sets :ingress_priority and :egress_priority to the same value

    next unless property_is_set?(property)
    new_value = new_resource.send(property)

    if property == :rules_str
      # quote the values in the rich rule just like firewalld does so it's idempotent
      # 'rule family=ipv4 source address=192.168.0.14 accept' ➔ 'rule family="ipv4" source address="192.168.0.14" accept'
      new_value = new_value.map { |rule| rule.gsub(/(\b\w+=)([^"\s]+)/, '\1"\2"') }
      new_resource.rules_str = new_value
    end

    if [:ports, :source_ports].include?(property)
      new_value = DBus.variant('a(ss)', new_value.map { |e| e.split('/') })
    elsif [:forward_ports].include?(property)
      new_value = forward_ports_to_dbus(new_resource)
    end
    converge_if_changed property do
      zone.update2({ property.to_s => new_value })
      reload = true
    end
  end

  if reload
    converge_by ['reload permanent configuration of firewalld'] do
      fw.reload
    end
  end
end

action_class do
  include FirewallCookbook::Helpers::FirewalldDBus
end
