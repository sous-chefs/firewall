unified_mode true

provides :firewalld_config,
         os: 'linux'

property :default_zone,
         String,
         description: 'Set default zone for connections and interfaces where no zone has been selected to zone. Setting the default zone changes the zone for the connections or interfaces, that are using the default zone.'
property :log_denied,
         String,
         equal_to: %w(all unicast broadcast multicast off),
         description: 'Set LogDenied value to value. If LogDenied is enabled, then logging rules are added right before reject and drop rules in the INPUT, FORWARD and OUTPUT chains for the default rules and also final reject and drop rules in zones.'

load_current_value do |_new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1']
  interface = firewalld_object['org.fedoraproject.FirewallD1']

  default_zone interface.getDefaultZone
  log_denied interface.getLogDenied
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)

  converge_if_changed :default_zone do
    fw.setDefaultZone new_resource.default_zone
  end

  converge_if_changed :log_denied do
    fw.setLogDenied new_resource.log_denied
  end
end

action_class do
  include FirewallCookbook::Helpers::FirewalldDBus
end
