unified_mode true

provides :firewalld_ipset,
         os: 'linux'

property :version,
         String,
         description: 'see version attribute of ipset tag in firewalld.ipset(5).'
property :short,
         String,
         name_property: true,
         description: 'see short tag in firewalld.ipset(5).'
property :description,
         String,
         description: 'see description tag in firewalld.ipset(5).'
property :type,
         String,
         default: 'hash:ip',
         description: 'see type attribute of ipset tag in firewalld.ipset(5).',
         equal_to:
           %w(hash:ip hash:ip,mark hash:ip,port hash:ip,port,ip hash:ip,port,net hash:mac hash:net hash:net,iface hash:net,net hash:net,port hash:net,port,net)
property :options,
         Hash,
         description: 'hash of {option : value} . See options tag in firewalld.ipset(5).'
property :entries,
         [Array, String],
         description: 'array of entries, see entry tag in firewalld.ipset(5).',
         coerce: proc { |o| Array(o) }

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  fw_config = firewalld_object['org.fedoraproject.FirewallD1.config']
  if fw_config.getIPSetNames.include?(new_resource.short)
    ipset_path = fw_config.getIPSetByName(new_resource.short)
    object = firewalld_service[ipset_path]
    config_ipset = object['org.fedoraproject.FirewallD1.config.ipset']
    settings = config_ipset.getSettings
    version settings[0]
    # short settings[1]
    description settings[2]
    type settings[3]
    options settings[4]
    entries settings[5]
  else
    Chef::Log.info "Ipset #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  reload = false
  if !fw_config.getIPSetNames.include?(new_resource.short)
    values = [
      new_resource.version || '',
      new_resource.short,
      default_description(new_resource),
      new_resource.type,
      new_resource.options || {},
      new_resource.entries,
    ]
    converge_by "Add ipset #{new_resource.short}" do
      fw_config.addIPSet(new_resource.short, values)
    end
    reload = true
  else
    ipset_path = fw_config.getIPSetByName(new_resource.short)
    ipset = ipset_interface(dbus, ipset_path)
    converge_if_changed :version do
      ipset.setVersion new_resource.version
      reload = true
    end
    converge_if_changed :description do
      ipset.setDescriptions default_description(new_resource)
      reload = true
    end
    converge_if_changed :type do
      ipset.setType new_resource.type
      reload = true
    end
    converge_if_changed :options do
      ipset.setOptions(new_resource.options || {})
      reload = true
    end
    converge_if_changed :entries do
      ipset.setEntries new_resource.entries
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
