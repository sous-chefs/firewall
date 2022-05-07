unified_mode true

provides :firewalld_icmptype,
         os: 'linux'

property :version,
         String,
         default: '',
         description: 'see version attribute of icmptype tag in firewalld.icmptype(5).'
property :name,
         String,
         description: 'see short tag in firewalld.icmptype(5).'
property :description,
         String,
         description: 'see description tag in firewalld.icmptype(5).'
property :destinations,
         ['ipv4', 'ipv6', %w(ipv4 ipv6)],
         default: 'ipv4',
         description: 'array, either empty or containing strings \'ipv4\' and/or \'ipv6\', see destination tag in firewalld.icmptype(5).'

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  interface = firewalld_object['org.fedoraproject.FirewallD1.config']
  begin
    icmptype_path = interface.getIcmpTypeByName(new_resource.name)
    object = firewalld_service[icmptype_path]
    interface = object['org.fedoraproject.FirewallD1.config.icmptype']
    settings = interface.getSettings
    version settings[0]
    # name settings[1]
    description settings[2]
    destinations settings[3]
  rescue DBus::Error
    Chef::Log.info "IcmpType #{new_resource.name} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw_config = config_interface(dbus)
  fw = firewalld_interface(dbus)
  reload = false
  begin
    icmptype_path = fw_config.getIcmpTypeByName(new_resource.name)
    icmptype = icmptype_interface(dbus, icmptype_path)

    reload = false
    values = properties.map do |property|
      new_resource.send(property)
    end
    icmptype.update(values)
  rescue
    values = [
      new_resource.version,
      new_resource.name,
      new_resource.description || default_description(new_resource),
      new_resource.destinations,
    ]
    converge_by "Add IcmpType #{new_resource.name}" do
      fw_config.addIcmpType(new_resource.name, values)
    end
    reload = true
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
