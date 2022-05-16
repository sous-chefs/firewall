unified_mode true

provides :firewalld_service,
         os: 'linux'

property :version,
         String,
         description: 'see version attribute of service tag in firewalld.service(5).'
property :short,
         String,
         name_property: true,
         description: 'see short tag in firewalld.service(5).'
property :description,
         String,
         description: 'see description tag in firewalld.service(5).'
property :ports,
         [Array, String],
         description: 'array of port and protocol pairs. See port tag in firewalld.service(5).',
         coerce: proc { |o| Array(o) }
property :module_names,
         [Array, String],
         description: 'array of kernel netfilter helpers, see module tag in firewalld.service(5).',
         coerce: proc { |o| Array(o) }
property :destination,
         Hash,
         description: 'hash of {IP family : IP address} where \'IP family\' key can be either \'ipv4\' or \'ipv6\'. See destination tag in firewalld.service(5).'
property :protocols,
         [Array, String],
         description: 'array of protocols, see protocol tag in firewalld.service(5).',
         coerce: proc { |o| Array(o) }
property :source_ports,
         [Array, String],
         description: 'array of port and protocol pairs. See source-port tag in firewalld.service(5).',
         coerce: proc { |o| Array(o) }
property :includes,
         [Array, String],
         description: 'array of service includes, see include tag in firewalld.service(5).',
         coerce: proc { |o| Array(o) }
property :helpers,
         [Array, String],
         description: 'array of service helpers, see helper tag in firewalld.service(5).',
         coerce: proc { |o| Array(o) }

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  fw_config = firewalld_object['org.fedoraproject.FirewallD1.config']
  if fw_config.getServiceNames.include?(new_resource.short)
    service_path = fw_config.getServiceByName(new_resource.short)
    object = firewalld_service[service_path]
    config_service = object['org.fedoraproject.FirewallD1.config.service']
    config_service.getSettings2.each do |k, v|
      send(k, v)
    end
  else
    Chef::Log.info "Service #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  reload = false
  unless fw_config.getServiceNames.include?(new_resource.short)
    fw_config.addService2(new_resource.short, {})
  end

  service_path = fw_config.getServiceByName(new_resource.short)
  service = service_interface(dbus, service_path)
  properties = new_resource.class.state_properties.map(&:name)
  properties.each do |property|
    new_value = new_resource.send(property)
    next unless new_value
    if [:ports, :source_ports].include?(property)
      new_value = DBus.variant('a(ss)', new_value.map { |e| e.split('/') })
    elsif property == :description
      new_value = default_description(new_resource)
    end
    converge_if_changed property do
      key = property == :short ? 'name' : property.to_s
      service.update2({ key => new_value })
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
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::FirewalldDBus
end
