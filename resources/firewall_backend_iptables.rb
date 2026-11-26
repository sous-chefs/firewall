# frozen_string_literal: true

provides :firewall_backend_iptables
unified_mode true
use '_partial/_firewall'

action :install do
  package(platform_family?('debian') ? 'iptables-persistent' : %w(iptables iptables-services)) do
    options new_resource.package_options if new_resource.package_options
  end
  directory '/etc/iptables' if platform_family?('debian')
  iptables_commands(new_resource).each do |family|
    file rules_path(family) do
      content '# created by chef to allow service to start'
      action :create_if_missing
    end
  end
  firewall_services.each do |unit|
    systemd_unit "#{unit}.service" do
      action %i(enable start)
    end
  end
end

action :restart do
  desired = Marshal.load(Marshal.dump(new_resource.rules))
  iptables_commands(new_resource).each do |family|
    defaults = new_resource.ruleset || {
      '*filter' => 1, ":INPUT #{new_resource.input_policy}" => 2,
      ":FORWARD #{new_resource.forward_policy}" => 3, ":OUTPUT #{new_resource.output_policy}" => 4, 'COMMIT_FILTER' => 100
    }
    desired[family] = (desired[family] || {}).merge(defaults)
    nat_rules = {}
    new_resource.rule_resources.each do |rule|
      next if family == 'iptables' && ipv6_rule?(rule)
      next if family == 'ip6tables' && ipv4_rule?(rule)

      target = %i(pre post).include?(rule.direction) && !defaults.key?('*nat') ? nat_rules : desired[family]
      target[build_firewall_rule(node, rule, family == 'ip6tables')] = rule.position
    end
    contents = build_rule_file(desired[family])
    if !defaults.key?('*nat') && (!nat_rules.empty? || managed_tables(family).include?('nat'))
      nat_defaults = { '*nat' => 1, ':PREROUTING ACCEPT' => 2, ':INPUT ACCEPT' => 3,
                       ':OUTPUT ACCEPT' => 4, ':POSTROUTING ACCEPT' => 5, 'COMMIT_NAT' => 100 }
      contents << build_rule_file(nat_defaults.merge(nat_rules))
    end
    path = rules_path(family)
    execute "load #{new_resource.name} #{family}" do
      command ["#{family}-restore"]
      input contents
      only_if { !::File.exist?(path) || ::File.read(path) != contents }
    end
    file path do
      content contents
      mode '0600'
    end
  end
end

%i(flush disable delete).each do |operation|
  action operation do
    iptables_commands(new_resource).each do |family|
      managed_tables(family).each do |table|
        execute "flush #{new_resource.name} #{family} #{table}" do
          command [family, '-t', table, '-F']
          only_if { operation == :flush ? ::File.exist?(rules_path(family)) : configured_rules?(family) }
        end
        next if operation == :flush
        managed_policies(family).fetch(table, []).each do |chain|
          execute "allow #{new_resource.name} #{family} #{table} #{chain}" do
            command [family, '-t', table, '-P', chain, 'ACCEPT']
            only_if { configured_rules?(family) }
          end
        end
      end
      file rules_path(family) do
        content '# created by chef to allow service to start'
        action(operation == :delete ? :delete : :create)
      end
    end
    if operation != :flush
      firewall_services.each do |unit|
        systemd_unit "#{unit}.service" do
          action %i(disable stop)
        end
      end
    end
    if operation == :delete
      package(platform_family?('debian') ? 'iptables-persistent' : %w(iptables iptables-services)) do
        action :remove
      end
    end
  end
end

action :save do
  raise ArgumentError, ':save is only supported by the firewalld backend'
end

action_class do
  include FirewallCookbook::Helpers::Iptables

  def rules_path(family)
    if platform_family?('debian')
      "/etc/iptables/rules.#{family == 'ip6tables' ? 'v6' : 'v4'}"
    else
      "/etc/sysconfig/#{family}"
    end
  end

  def firewall_services
    platform_family?('debian') ? ['netfilter-persistent'] : iptables_commands(new_resource)
  end

  def managed_tables(family)
    path = rules_path(family)
    return ['filter'] unless ::File.exist?(path)

    (['filter'] + ::File.read(path).scan(/^\*(\w+)$/).flatten).uniq
  end

  def configured_rules?(family)
    path = rules_path(family)
    ::File.exist?(path) && ::File.read(path) != '# created by chef to allow service to start'
  end

  def managed_policies(family)
    policies = { 'filter' => %w(INPUT OUTPUT FORWARD) }
    path = rules_path(family)
    return policies unless ::File.exist?(path)

    table = nil
    ::File.foreach(path) do |line|
      table = Regexp.last_match(1) if line =~ /^\*(\w+)$/
      next unless table && line =~ /^:(\S+)\s+(ACCEPT|DROP)\b/

      (policies[table] ||= []) << Regexp.last_match(1)
    end
    policies.transform_values(&:uniq)
  end
end
