unified_mode true

provides :firewalld_zone,
         os: 'linux'

property :description,
         [Array, String],
         description: 'see description tag in firewalld.zone(5).'
property :forward,
         [true, false],
         description: 'see forward tag in firewalld.zone(5).'
property :forward_ports,
         [Array, String],
         description: 'array of (port, protocol, to-port, to-addr). See forward-port tag in firewalld.zone(5).'
property :icmp_block_inversion,
         [true, false],
         description: 'see icmp-block-inversion tag in firewalld.zone(5).'
property :icmp_blocks,
         [Array, String],
         description: 'array of icmp-blocks. See icmp-block tag in firewalld.zone(5).'
property :interfaces,
         [Array, String],
         description: 'array of interfaces. See interface tag in firewalld.zone(5).'
property :masquerade,
         [true, false],
         description: 'see masquerade tag in firewalld.zone(5).'
property :ports,
         [Array, String],
         description: 'array of port and protocol pairs. See port tag in firewalld.zone(5).'
property :protocols,
         [Array, String],
         description: 'array of protocols, see protocol tag in firewalld.zone(5).'
property :rules_str,
         [Array, String],
         description: 'array of rich-language rules. See rule tag in firewalld.zone(5).'
property :services,
         [Array, String],
         description: 'array of service names, see service tag in firewalld.zone(5).'
property :short,
         String,
         name_property: true,
         description: 'see short tag in firewalld.zone(5).'
property :source_ports,
         [Array, String],
         description: 'array of port and protocol pairs. See source-port tag in firewalld.zone(5).'
property :sources,
         [Array, String],
         description: 'array of source addresses. See source tag in firewalld.zone(5).'
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
  interface = firewalld_object['org.fedoraproject.FirewallD1.config']
  begin
    zone_path = interface.getZoneByName(new_resource.short)
    object = firewalld_service[zone_path]
    interface = object['org.fedoraproject.FirewallD1.config.zone']
    interface.getSettings2.each do |k, v|
      send(k, v)
    end
  rescue DBus::Error
    Chef::Log.info "Zone #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  zone_path = ''
  begin
    zone_path = fw_config.getZoneByName(new_resource.short)
  rescue
    fw_config.addZone2(new_resource.short, {})
    fw.reload
    zone_path = fw_config.getZoneByName(new_resource.short)
  end
  zone = zone_interface(dbus, zone_path)

  reload = false
  properties = new_resource.class.state_properties.map(&:name)
  properties.each do |property|
    reload = false
    new_value = new_resource.send(property)
    if [:ports, :source_ports].include?(property)
      new_value = DBus.variant('a(ss)', new_value)
    elsif [:forward_ports].include?(property)
      new_value = DBus.variant('a(ssss)', new_value)
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
