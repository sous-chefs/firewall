unified_mode true

provides :firewalld_helper,
         os: 'linux'

property :version,
         String,
         default: '',
         description: 'see version attribute of helper tag in firewalld.helper(5).'
property :name,
         String,
         name_property: true,
         description: 'see short tag in firewalld.helper(5).'
property :description,
         String,
         description: 'see description tag in firewalld.helper(5).'
property :family,
         [String, Array],
         equal_to: ['ipv4', 'ipv6', %w(ipv4 ipv6)],
         default: 'ipv4',
         description: 'see family tag in firewalld.helper(5).'
property :nf_module,
         String,
         description: 'see module tag in firewalld.helper(5).'
property :ports,
         Array,
         default: [],
         description: 'array of port and protocol pairs. See port tag in firewalld.helper(5).'

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  interface = firewalld_object['org.fedoraproject.FirewallD1.config']
  begin
    helper_path = interface.getHelperByName(new_resource.name)
    object = firewalld_service[helper_path]
    interface = object['org.fedoraproject.FirewallD1.config.helper']
    settings = interface.getSettings
    version settings[0]
    # name settings[1]
    description settings[2]
    family settings[3]
    nf_module settings[4]
    ports settings[5]
  rescue DBus::Error
    Chef::Log.info "Helper #{new_resource.name} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  reload = false
  begin
    helper_path = interface.getHelperByName(new_resource.name)
    helper = helper_interface(dbus, helper_path)

    reload = false
    values = properties.map do |property|
      new_resource.send(property)
    end
    helper.update(values)
  rescue
    values = [
      new_resource.version,
      new_resource.name,
      new_resource.description || default_description(new_resource),
      new_resource.family,
      new_resource.nf_module,
      new_resource.ports,
    ]
    converge_by "Add Helper #{new_resource.name}" do
      fw_config.addHelper(new_resource.name, values)
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
