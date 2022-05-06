unified_mode true

provides :firewalld_icmptype,
         os: 'linux'

property :version,
         String,
         default: '',
         description: 'see version attribute of icmptype tag in firewalld.icmptype(5).'
property :short,
         String,
         name_property: true,
         description: 'see short tag in firewalld.icmptype(5).'
property :description,
         String,
         description: 'see description tag in firewalld.icmptype(5).'
property :destinations,
         Array,
         equal_to: [['ipv4'], ['ipv6'], %w(ipv4 ipv6)],
         default: 'ipv4',
         description: 'array, either empty or containing strings \'ipv4\' and/or \'ipv6\', see destination tag in firewalld.icmptype(5).',
         coerce: proc { |o| Array(o) }

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  fw_config = firewalld_object['org.fedoraproject.FirewallD1.config']
  if fw_config.getIcmpTypeNames.include?(new_resource.short)
    icmptype_path = fw_config.getIcmpTypeByName(new_resource.short)
    object = firewalld_service[icmptype_path]
    config_icmptype = object['org.fedoraproject.FirewallD1.config.icmptype']
    settings = config_icmptype.getSettings
    version settings[0]
    # short settings[1]
    description settings[2]
    destinations settings[3]
  else
    Chef::Log.info "IcmpType #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw_config = config_interface(dbus)
  fw = firewalld_interface(dbus)
  reload = false
  icmptype_names = fw_config.getIcmpTypeNames
  if !icmptype_names.include?(new_resource.short)
    values = [
      new_resource.version,
      new_resource.short,
      default_description(new_resource),
      new_resource.destinations,
    ]

    converge_by "Add IcmpType #{new_resource.short}" do
      fw_config.addIcmpType(new_resource.short, values)
    end
    reload = true
  else
    icmptype_path = fw_config.getIcmpTypeByName(new_resource.short)
    icmptype = icmptype_interface(dbus, icmptype_path)
    converge_if_changed :version do
      icmptype.setVersion new_resource.version
      reload = true
    end
    converge_if_changed :description do
      icmptype.setDescription default_description(new_resource)
      reload = true
    end
    converge_if_changed :destinations do
      icmptype.setDestinations new_resource.destinations
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
