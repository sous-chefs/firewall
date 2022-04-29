unified_mode true

provides :firewalld_policy,
         os: 'linux'

property :description,   # (s): see description tag in firewalld.policy(5).
         String
property :egress_zones,  # as: array of zone names. See egress-zone tag in firewalld.policy(5).
         [Array, String]
property :forward_ports, # (a(ssss)): array of (port, protocol, to-port, to-addr). See forward-port tag in firewalld.policy(5).
         [Array, String]
property :icmp_blocks,   # (as): array of icmp-blocks. See icmp-block tag in firewalld.policy(5).
         [Array, String]
property :ingress_zones, # as: array of zone names. See ingress-zone tag in firewalld.policy(5).
         [Array, String]
property :masquerade,    # (b): see masquerade tag in firewalld.policy(5).
         [true, false]
property :ports,         # (a(ss)): array of port and protocol pairs. See port tag in firewalld.policy(5).
         [Array, String]
property :priority,      # (i): see priority tag in firewalld.policy(5).
         Integer
property :protocols,     # (as): array of protocols, see protocol tag in firewalld.policy(5).
         [Array, String]
property :rich_rules,    # (as): array of rich-language rules. See rule tag in firewalld.policy(5).
         [Array, String]
property :services,      # (as): array of service names, see service tag in firewalld.policy(5).
         [Array, String]
property :short, # (s): see short tag in firewalld.policy(5).
         String,
         name_property: true
property :source_ports,  # (a(ss)): array of port and protocol pairs. See source-port tag in firewalld.policy(5).
         [Array, String]
property :target,        # (s): see target attribute of policy tag in firewalld.policy(5).
         String
property :version,       # (s): see version attribute of policy tag in firewalld.policy(5).
         String

load_current_value do |new_resource|
  sysbus = DBus.system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  interface = firewalld_object['org.fedoraproject.FirewallD1.config']
  if interface.getPolicyNames.include?(new_resource.short)
    policy_path = interface.getPolicyByName(new_resource.short)
    object = firewalld_service[policy_path]
    interface = object['org.fedoraproject.FirewallD1.config.policy']
    interface.getSettings.each do |k, v|
      send(k, v)
    end
  else
    Chef::Log.info "Zone #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = DBus.system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)

  policy_path = ''
  begin
    policy_path = fw_config.getPolicyByName(new_resource.short)
  rescue
    fw_config.addPolicy(new_resource.short, {})
    fw.reload
    policy_path = fw_config.getPolicyByName(new_resource.short)
  end
  policy = policy_interface(dbus, policy_path)
  reload = false
  properties = new_resource.class.state_properties.map(&:name)
  properties.each do |property|
    reload = false
    new_value = new_resource.send(property)
    if [:ports, :source_ports].include?(property)
      new_value = DBus.variant('a(ss)', new_value)
    elsif [:forward_ports].include?(property)
      new_value = DBus.variant('a(ssss)', new_value)
    elsif [:priority].include?(property)
      new_value = DBus.variant('i', new_value)
    end
    converge_if_changed property do
      policy.update({ property.to_s => new_value })
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
