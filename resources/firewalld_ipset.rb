unified_mode true

provides :firewalld_ipset,
         os: 'linux'

property :version,
         String,
         description: 'see version attribute of ipset tag in firewalld.ipset(5).'
property :name,
         String,
         description: 'see short tag in firewalld.ipset(5).'
property :description,
         String,
         description: 'see description tag in firewalld.ipset(5).'
property :type,
         String,
         default: 'hash:ip',
         description: 'see type attribute of ipset tag in firewalld.ipset(5).'
property :options,
         [Hash],
         default: {},
         description: 'hash of {option : value} . See options tag in firewalld.ipset(5).'
property :entries,
         [Array, String],
         description: 'array of entries, see entry tag in firewalld.ipset(5).',
         coerce: proc { |o| Array(o) }

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  interface = firewalld_object['org.fedoraproject.FirewallD1.config']
  begin
    ipset_path = interface.getIPSetByName(new_resource.name)
    object = firewalld_service[ipset_path]
    interface = object['org.fedoraproject.FirewallD1.config.ipset']
    settings = interface.getSettings
    version settings[0]
    # name settings[1]
    description settings[2]
    type settings[3]
    options settings[4]
    entries settings[5]
  rescue DBus::Error
    Chef::Log.info "Ipset #{new_resource.name} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  reload = false
  begin
    ipset_path = fw_config.getIpsetByName(new_resource.name)
    ipset = ipset_interface(dbus, ipset_path)

    reload = false
    values = properties.map do |property|
      new_resource.send(property)
    end
    ipset.update(values)
  rescue
    values = [
      new_resource.version || '',
      new_resource.name,
      new_resource.description || default_description(new_resource),
      new_resource.type,
      new_resource.options,
      new_resource.entries,
    ]
    converge_by "Add ipset #{new_resource.name}" do
      fw_config.addIPSet(new_resource.name, values)
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
