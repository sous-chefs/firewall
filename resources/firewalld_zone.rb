unified_mode true

provides :firewalld_zone,
         os: 'linux'

property :description,
         [Array, String]
property :forward,
         [true, false]
property :forward_ports,
         [Array, String]
property :icmp_block_inversion,
         [true, false]
property :icmp_blocks,
         [Array, String]
property :interfaces,
         [Array, String]
property :masquerade,
         [true, false]
property :ports,
         [Array, String]
property :protocols,
         [Array, String]
property :rules_str,
         [Array, String]
property :services,
         [Array, String]
property :short,
         String,
         name_property: true
property :source_ports,
         [Array, String]
property :sources,
         [Array, String]
property :target,
         String
property :version,
         String

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
