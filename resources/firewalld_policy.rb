unified_mode true

provides :firewalld_policy,
         os: 'linux'

property :description,
         String,
         description: 'see description tag in firewalld.policy(5).'
property :egress_zones,
         [Array, String],
         description: 'array of zone names. See egress-zone tag in firewalld.policy(5).'
property :forward_ports,
         [Array, String],
         description: 'array of [port, protocol, to-port, to-addr]. See forward-port tag in firewalld.policy(5).'
property :icmp_blocks,
         [Array, String],
         description: 'array of icmp-blocks. See icmp-block tag in firewalld.policy(5).'
property :ingress_zones,
         [Array, String],
         description: 'array of zone names. See ingress-zone tag in firewalld.policy(5).'
property :masquerade,
         [true, false],
         description: 'see masquerade tag in firewalld.policy(5).'
property :ports,
         [Array, String],
         description: 'array of port and protocol pairs. See port tag in firewalld.policy(5).'
property :priority,
         Integer,
         description: 'see priority tag in firewalld.policy(5).'
property :protocols,
         [Array, String],
         description: 'array of protocols, see protocol tag in firewalld.policy(5).'
property :rich_rules,
         [Array, String],
         description: 'array of rich-language rules. See rule tag in firewalld.policy(5).'
property :services,
         [Array, String],
         description: 'array of service names, see service tag in firewalld.policy(5).'
property :short,
         String,
         description: 'see short tag in firewalld.policy(5).',
         name_property: true
property :source_ports,
         [Array, String],
         description: 'array of port and protocol pairs. See source-port tag in firewalld.policy(5).'
property :target,
         String,
         description: 'see target attribute of policy tag in firewalld.policy(5).'
property :version,
         String,
         description: 'see version attribute of policy tag in firewalld.policy(5).'

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
