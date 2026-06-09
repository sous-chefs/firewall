unified_mode true

use '_partial/_firewalld_zone_policy'

provides :firewalld_policy,
         os: 'linux'
provides :firewall_policy,
         os: 'linux'

property :egress_zones,
         [Array, String],
         description: 'array of zone names. See egress-zone tag in firewalld.policy(5).',
         coerce: proc { |o| Array(o) }
property :ingress_zones,
         [Array, String],
         description: 'array of zone names. See ingress-zone tag in firewalld.policy(5).',
         coerce: proc { |o| Array(o) }
property :rich_rules,
         [Array, String],
         description: 'array of rich-language rules. See rule tag in firewalld.policy(5).',
         coerce: proc { |o| Array(o) }

include FirewallCookbook::Helpers::FirewalldDBus

load_current_value do |new_resource|
  sysbus = dbus_system_bus
  firewalld_service = sysbus['org.fedoraproject.FirewallD1']
  firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
  fw_config = firewalld_object['org.fedoraproject.FirewallD1.config']
  if fw_config.getPolicyNames.include?(new_resource.short)
    policy_path = fw_config.getPolicyByName(new_resource.short)
    object = firewalld_service[policy_path]
    config_policy = object['org.fedoraproject.FirewallD1.config.policy']
    config_policy.getSettings.each do |k, v|
      next unless new_resource.class.properties.key?(k.to_sym)

      # Load the current value of ports in the same format as the resource property to make it idempotent
      v = v.map { |port, protocol| "#{port}/#{protocol}" } if %w(ports source_ports).include?(k)
      send(k, v)
    end
  else
    Chef::Log.info "Zone #{new_resource.short} does not exist. Will be created."
  end
end

action :update do
  dbus = dbus_system_bus
  fw = firewalld_interface(dbus)
  fw_config = config_interface(dbus)
  reload = false

  unless fw_config.getPolicyNames.include?(new_resource.short)
    fw_config.addPolicy(new_resource.short, {})
  end
  policy_path = fw_config.getPolicyByName(new_resource.short)
  policy = policy_interface(dbus, policy_path)
  properties = new_resource.class.state_properties.map(&:name)
  properties.each do |property|
    next unless property_is_set?(property)

    new_value = new_resource.send(property)

    if property == :rich_rules
      # quote the values in the rich rule just like firewalld does so it's idempotent
      # 'rule family=ipv4 source address=192.168.0.14 accept' ➔ 'rule family="ipv4" source address="192.168.0.14" accept'
      new_value = new_value.map { |rule| rule.gsub(/(\b\w+=)([^"\s]+)/, '\1"\2"') }
      new_resource.rich_rules = new_value
    end

    if [:ports, :source_ports].include?(property)
      new_value = dbus_variant('a(ss)', new_value.map { |e| e.split('/') })
    elsif [:forward_ports].include?(property)
      new_value = forward_ports_to_dbus(new_resource)
    elsif [:priority].include?(property)
      new_value = dbus_variant('i', new_value)
    elsif [:masquerade].include?(property)
      new_value = dbus_variant('b', new_value)
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
