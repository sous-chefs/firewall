unified_mode true

provides :firewalld_helper,
         os: 'linux'

property :version,
         String,
         default: '',
         description: 'see version attribute of helper tag in firewalld.helper(5).'
property :short,
         String,
         name_property: true,
         description: 'see short tag in firewalld.helper(5).'
property :description,
         String,
         description: 'see description tag in firewalld.helper(5).'
property :family,
         String,
         equal_to: %w(ipv4 ipv6),
         default: 'ipv4',
         description: 'see family tag in firewalld.helper(5).'
property :nf_module,
         String,
         description: 'see module tag in firewalld.helper(5).'
property :ports,
         [Array, String],
         default: [],
         description: 'array of port and protocol pairs. See port tag in firewalld.helper(5).',
         coerce: proc { |o| Array(o) }

load_current_value do |new_resource|
  dbus = DBus.system_bus
  firewalld_service = dbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  fw_config = firewalld_object['org.fedoraproject.FirewallD1.config']
  if fw_config.getHelperNames.include?(new_resource.short)
    helper_path = fw_config.getHelperByName(new_resource.short)
    object = firewalld_service[helper_path]
    config_helper = object['org.fedoraproject.FirewallD1.config.helper']
    settings = config_helper.getSettings
    version settings[0]
    # short settings[1]
    description settings[2]
    family settings[3]
    nf_module settings[4]
    ports settings[5]
  else
    Chef::Log.info "Helper #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  helper_names = fw_config.getHelperNames
  reload = false
  if !helper_names.include?(new_resource.short)
    values = [
      new_resource.version,
      new_resource.short,
      default_description(new_resource),
      new_resource.family,
      new_resource.nf_module,
      new_resource.ports.map { |e| e.split('/') },
    ]
    converge_by "Add Helper #{new_resource.short}" do
      fw_config.addHelper(new_resource.short, values)
    end
    reload = true
  else
    helper_path = fw_config.getHelperByName(new_resource.short)
    helper = helper_interface(dbus, helper_path)
    converge_if_changed :version do
      helper.setVersion new_resource.version
      reload = true
    end
    converge_if_changed :description do
      helper.setDescription default_description(new_resource)
      reload = true
    end
    converge_if_changed :family do
      helper.setFamily new_resource.family
      reload = true
    end
    converge_if_changed :nf_module do
      helper.setModule new_resource.nf_module
      reload = true
    end
    converge_if_changed :ports do
      helper.setPorts new_resource.ports.map { |e| e.split('/') }
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
