unified_mode true

provides :firewalld_service,
         os: 'linux'

property :version,
         String,
         description: 'see version attribute of service tag in firewalld.service(5).'
property :name,
         String,
         description: 'see short tag in firewalld.service(5).'
property :description,
         String,
         description: 'see description tag in firewalld.service(5).'
property :ports,
         [Array, String],
         description: 'array of port and protocol pairs. See port tag in firewalld.service(5).'
property :module_names,
         [Array, String],
         description: 'array of kernel netfilter helpers, see module tag in firewalld.service(5).'
property :destination,
         Hash,
         description: 'hash of {IP family : IP address} where \'IP family\' key can be either \'ipv4\' or \'ipv6\'. See destination tag in firewalld.service(5).'
property :protocols,
         [Array, String],
         description: 'array of protocols, see protocol tag in firewalld.service(5).'
property :source_ports,
         [Array, String],
         description: 'array of port and protocol pairs. See source-port tag in firewalld.service(5).'
property :includes,
         [Array, String],
         description: 'array of service includes, see include tag in firewalld.service(5).'
property :helpers,
         [Array, String],
         description: 'array of service helpers, see helper tag in firewalld.service(5).'

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  interface = firewalld_object['org.fedoraproject.FirewallD1.config']
  begin
    service_path = interface.getServiceByName(new_resource.name)
    object = firewalld_service[service_path]
    interface = object['org.fedoraproject.FirewallD1.config.service']
    interface.getSettings2.each do |k, v|
      send(k, v)
    end
  rescue DBus::Error
    Chef::Log.info "Service #{new_resource.name} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  service_path = ''
  begin
    service_path = fw_config.getServiceByName(new_resource.name)
  rescue
    fw_config.addService2(new_resource.name, {})
    fw.reload
    service_path = fw_config.getServiceByName(new_resource.name)
  end

  service = service_interface(dbus, service_path)

  reload = false
  properties = new_resource.class.state_properties.map(&:name)
  properties.each do |property|
    reload = false
    new_value = new_resource.send(property)
    if [:ports, :source_ports].include?(property)
      new_value = DBus.variant('a(ss)', new_value)
    end
    converge_if_changed property do
      service.update2({ property.to_s => new_value })
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
