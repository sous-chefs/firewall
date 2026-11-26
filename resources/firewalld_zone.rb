# frozen_string_literal: true

unified_mode true
include FirewallCookbook::Helpers::FirewalldDBus

provides :firewalld_zone,
         os: 'linux'

property :description,
         String,
         default: lazy { name },
         description: 'see description tag in firewalld.zone(5).'
property :forward,
         [true, false],
         description: 'see forward tag in firewalld.zone(5).'
property :egress_priority, Integer
property :ingress_priority, Integer
property :priority, Integer, desired_state: false
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
property :interfaces,
         [Array, String],
         description: 'array of interfaces. See interface tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
property :masquerade,
         [true, false],
         description: 'see masquerade tag in firewalld.zone(5).'
property :ports,
         [Array, String],
         description: 'array of port and protocol pairs. See port tag in firewalld.zone(5).',
         coerce: proc { |o| Array(o) }
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
         description: 'array of port and protocol pairs. See source-port tag in firewalld.zone(5).',
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
      next unless new_resource.class.properties.key?(k.to_sym)
      send(k, normalise_dbus_value(k, v))
    end
    rules_str new_resource.rules_str if same_rich_rules?(rules_str || [], new_resource.rules_str)
  else
    Chef::Log.info "Zone #{new_resource.short} does not exist. Will be created."
    current_value_does_not_exist!
  end
end

action :update do
  if property_is_set?(:priority) && (property_is_set?(:ingress_priority) || property_is_set?(:egress_priority))
    raise ArgumentError, 'Use priority alone, or ingress_priority/egress_priority, not both'
  end
  if property_is_set?(:priority)
    new_resource.ingress_priority new_resource.priority
    new_resource.egress_priority new_resource.priority
  end
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)

  reload = false
  unless fw_config.getZoneNames.include?(new_resource.short)
    converge_by "Add Zone #{new_resource.short}" do
      fw_config.addZone2(new_resource.short, { 'forward' => false })
    end
    return if whyrun_mode?
    reload = true
  end
  zone_path = fw_config.getZoneByName(new_resource.short)
  zone = zone_interface(dbus, zone_path)

  properties = new_resource.class.state_properties.map(&:name)
  properties.each do |property|
    new_value = new_resource.send(property)
    next if new_value.nil?
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

action :delete do
  delete_dbus_object('Zone', 'zone')
end

action_class do
  include FirewallCookbook::Helpers::FirewalldDBus
end
