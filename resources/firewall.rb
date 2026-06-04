# frozen_string_literal: true

unified_mode true

use '_partial/_firewall'

provides :firewall

action :install do
  return if disabled?(new_resource)

  case firewall_backend
  when :firewalld
    firewalld new_resource.name do
      package_options new_resource.package_options if property_is_set?(:package_options)
      action :install
    end

    declare_default_firewalld_rules
  when :iptables
    install_iptables
  when :nftables
    install_nftables
  when :ufw
    install_ufw
  when :windows
    service 'MpsSvc' do
      action [:enable, :start]
    end
  end
end

action :restart do
  return if disabled?(new_resource)

  case firewall_backend
  when :firewalld
    firewalld new_resource.name do
      action :restart
    end
  when :iptables
    rebuild_iptables
  when :nftables
    rebuild_nftables
  when :ufw
    rebuild_ufw
  when :windows
    rebuild_windows
  end
end

action :reload do
  return if disabled?(new_resource)

  case firewall_backend
  when :firewalld
    firewalld new_resource.name do
      action :reload
    end
  when :iptables
    rebuild_iptables
  when :nftables
    rebuild_nftables
  when :ufw
    rebuild_ufw
  when :windows
    rebuild_windows
  else
    raise "Unsupported firewall backend #{firewall_backend}"
  end
end

action :disable do
  return if disabled?(new_resource)

  case firewall_backend
  when :firewalld
    firewalld new_resource.name do
      action :disable
    end
  when :iptables
    ruby_block "disable iptables #{new_resource.name}" do
      block do
        iptables_flush!(new_resource)
        iptables_default_allow!(new_resource)
      end
    end

    iptables_service_names.each do |svc|
      service svc do
        action [:disable, :stop]
      end

      file iptables_rules_path(svc) do
        content '# created by chef to allow service to start'
      end
    end
  when :nftables
    nftables new_resource.name do
      action :disable
    end
  when :ufw
    file ufw_rules_filename do
      content '# created by chef to allow service to start'
    end

    ruby_block "disable ufw #{new_resource.name}" do
      block do
        ufw_disable! if ufw_active?
      end
    end
  when :windows
    ruby_block "disable windows firewall #{new_resource.name}" do
      block do
        disable! if active?
      end
    end

    service 'MpsSvc' do
      action [:disable, :stop]
    end
  end
end

action :flush do
  return if disabled?(new_resource)

  case firewall_backend
  when :firewalld
    firewalld new_resource.name do
      action :reload
    end
  when :iptables
    ruby_block "flush iptables #{new_resource.name}" do
      block do
        iptables_flush!(new_resource)
      end
    end

    iptables_service_names.each do |svc|
      file iptables_rules_path(svc) do
        content '# created by chef to allow service to start'
      end
    end
  when :nftables
    rebuild_nftables
  when :ufw
    ruby_block "flush ufw #{new_resource.name}" do
      block do
        ufw_reset!
      end
    end

    file ufw_rules_filename do
      content '# created by chef to allow service to start'
    end
  when :windows
    ruby_block "reset windows firewall #{new_resource.name}" do
      block do
        reset!
      end
    end
  end
end

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Iptables
  include FirewallCookbook::Helpers::Ufw
  include FirewallCookbook::Helpers::Windows

  def firewall_backend
    new_resource.backend || default_firewall_backend
  end

  def default_firewall_backend
    case node['platform_family']
    when 'debian'
      platform?('debian') ? :nftables : :ufw
    when 'amazon', 'fedora', 'rhel', 'suse'
      :firewalld
    when 'windows'
      :windows
    else
      :iptables
    end
  end

  def install_nftables
    nftables new_resource.name do
      rules default_nftables_rules
      action :install
    end
  end

  def install_iptables
    packages = platform_family?('debian') ? ['iptables-persistent'] : iptables_packages(new_resource)
    packages.each do |pkg|
      package pkg
    end

    iptables_service_names.each do |svc|
      file iptables_rules_path(svc) do
        content '# created by chef to allow service to start'
        action :create_if_missing
      end

      service svc do
        status_command 'true' if svc == 'netfilter-persistent'
        action [:enable, :start]
      end
    end
  end

  def install_ufw
    package 'ufw'

    template '/etc/default/ufw' do
      owner 'root'
      group 'root'
      mode '0644'
      source 'ufw/default.erb'
      cookbook 'firewall'
      variables(defaults: new_resource.ufw_defaults)
    end

    file ufw_rules_filename do
      content '# created by chef to allow service to start'
      action :create_if_missing
    end

    service 'ufw' do
      action :enable
    end
  end

  def rebuild_iptables
    log_iptables(new_resource)
    ensure_default_rules_exist(new_resource)
    collect_iptables_rules

    iptables_service_names.each do |svc|
      service svc do
        status_command 'true' if svc == 'netfilter-persistent'
        action :nothing
      end

      iptables_rule_files_for_service(svc).each do |iptables_type, rules_path|
        file rules_path do
          content build_rule_file(new_resource.rules[iptables_type])
          notifies :restart, "service[#{svc}]", :immediately
        end
      end
    end
  end

  def rebuild_nftables
    nftables new_resource.name do
      rules default_nftables_rules
      action :rebuild
    end
  end

  def rebuild_ufw
    new_resource.rules['ufw'] ||= {}
    collect_ufw_rules
    sorted_rules = new_resource.rules['ufw'].sort_by { |_rule, position| position }.map(&:first)

    ruby_block "apply ufw rules #{new_resource.name}" do
      action :nothing
      block do
        ufw_reset!
        ufw_logging!(new_resource.log_level) if new_resource.log_level
        sorted_rules.each { |cmd| ufw_rule!(cmd) }
        ufw_enable! unless ufw_active?
      end
    end

    file ufw_rules_filename do
      content build_rule_file(new_resource.rules['ufw'])
      notifies :run, "ruby_block[apply ufw rules #{new_resource.name}]", :immediately
    end
  end

  def rebuild_windows
    new_resource.rules['windows'] ||= {}
    collect_windows_rules
    policy_rule = "set currentprofile firewallpolicy #{new_resource.windows_policy[:input]},#{new_resource.windows_policy[:output]}"
    new_resource.rules['windows'][policy_rule] ||= 99_999
    sorted_rules = new_resource.rules['windows'].sort_by { |_rule, position| position }.map(&:first)

    ruby_block "apply windows firewall rules #{new_resource.name}" do
      action :nothing
      block do
        disable! if active?
        delete_all_rules!
        reset!
        sorted_rules.each { |cmd| add_rule!(cmd) }
        enable! unless active?
      end
    end

    file windows_rules_filename do
      content build_rule_file(new_resource.rules['windows'])
      notifies :run, "ruby_block[apply windows firewall rules #{new_resource.name}]", :immediately
    end
  end

  def collect_matching_rules(resource_name)
    default_firewall_rules + Chef.run_context.resource_collection.select do |item|
      item.resource_name == resource_name &&
        item.firewall_name == new_resource.name &&
        item.action.include?(:create) &&
        !item.should_skip?(:create)
    end
  end

  def collect_iptables_rules
    collect_matching_rules(:iptables_rule).each do |firewall_rule|
      types = if ipv6_rule?(firewall_rule)
                %w(ip6tables)
              elsif ipv4_rule?(firewall_rule)
                %w(iptables)
              else
                %w(iptables ip6tables)
              end

      types.each do |iptables_type|
        next if iptables_type == 'ip6tables' && !new_resource.ipv6_enabled

        rule = build_firewall_rule(node, firewall_rule, iptables_type == 'ip6tables')
        new_resource.rules[iptables_type][rule] = firewall_rule.position
      end
    end
  end

  def collect_ufw_rules
    collect_matching_rules(:ufw_rule).each do |firewall_rule|
      rule = FirewallCookbook::Helpers::Ufw.instance_method(:build_rule).bind(self).call(firewall_rule)
      new_resource.rules['ufw'][rule] = firewall_rule.position
    end
  end

  def collect_windows_rules
    collect_matching_rules(:windows_firewall_rule).each do |firewall_rule|
      rule = FirewallCookbook::Helpers::Windows.instance_method(:build_rule).bind(self).call(firewall_rule)
      new_resource.rules['windows'][rule] = firewall_rule.position
    end
  end

  def iptables_service_names
    return ['netfilter-persistent'] if platform_family?('debian')

    iptables_commands(new_resource)
  end

  def iptables_type_for_service(service_name)
    return 'iptables' if service_name == 'netfilter-persistent'

    service_name
  end

  def iptables_rule_files_for_service(service_name)
    if service_name == 'netfilter-persistent'
      files = { 'iptables' => iptables_rules_path('iptables') }
      files['ip6tables'] = iptables_rules_path('ip6tables') if new_resource.ipv6_enabled
      files
    else
      { iptables_type_for_service(service_name) => iptables_rules_path(service_name) }
    end
  end

  def iptables_rules_path(service_name)
    case service_name
    when 'netfilter-persistent', 'iptables'
      platform_family?('debian') ? '/etc/iptables/rules.v4' : '/etc/sysconfig/iptables'
    when 'ip6tables'
      platform_family?('debian') ? '/etc/iptables/rules.v6' : '/etc/sysconfig/ip6tables'
    else
      raise "Unsupported iptables service #{service_name}"
    end
  end

  def nftables_helper
    @nftables_helper ||= Object.new.tap do |helper|
      helper.extend(FirewallCookbook::Helpers)
      helper.extend(FirewallCookbook::Helpers::Nftables)
    end
  end

  def default_nftables_rules
    rules = {
      'add table inet filter' => 1,
      'add chain inet filter INPUT { type filter hook input priority 0 ; policy drop; }' => 2,
      'add chain inet filter OUTPUT { type filter hook output priority 0 ; policy accept; }' => 2,
      'add chain inet filter FORWARD { type filter hook forward priority 0 ; policy drop; }' => 2,
      'add table ip nat' => 1,
      'add chain ip nat POSTROUTING { type nat hook postrouting priority 100 ;}' => 2,
      'add chain ip nat PREROUTING { type nat hook prerouting priority -100 ;}' => 2,
      'add table ip6 nat' => 1,
      'add chain ip6 nat POSTROUTING { type nat hook postrouting priority 100 ;}' => 2,
      'add chain ip6 nat PREROUTING { type nat hook prerouting priority -100 ;}' => 2,
    }

    default_firewall_rules.each do |firewall_rule|
      rule = nftables_helper.build_firewall_rule(nftables_rule_from_firewall_rule(firewall_rule))
      rules[rule] = firewall_rule.position
    end

    rules
  end

  def declare_default_firewalld_rules
    if linux? && new_resource.allow_ssh
      firewalld_rich_rule 'allow world to ssh' do
        family :ipv4
        source '0.0.0.0/0'
        port 22
        protocol 'tcp'
        rule_action :accept
        action :add
      end
    end

    if linux? && new_resource.allow_mosh
      firewalld_rich_rule 'allow world to mosh' do
        family :ipv4
        source '0.0.0.0/0'
        port '60000-61000'
        protocol 'udp'
        rule_action :accept
        action :add
      end
    end
  end

  def default_firewall_rules
    rules = []

    rules << default_firewall_rule('allow world to ssh', port: 22) if linux? && new_resource.allow_ssh
    rules << default_firewall_rule('allow world to winrm', port: 5989) if windows? && new_resource.allow_winrm
    rules << default_firewall_rule('allow world to mosh', protocol: :udp, port: 60000..61000) if linux? && new_resource.allow_mosh

    if firewall_backend == :iptables
      rules << default_firewall_rule('allow loopback', interface: 'lo', protocol: :none) if new_resource.allow_loopback
      rules << default_firewall_rule('allow icmp', protocol: :icmp) if new_resource.allow_icmp
      rules << default_firewall_rule('established', stateful: [:related, :established], protocol: :none) if new_resource.allow_established
      rules << default_firewall_rule('ipv6_icmp', protocol: :'ipv6-icmp') if new_resource.ipv6_enabled && new_resource.allow_established
    elsif firewall_backend == :nftables
      rules << default_firewall_rule('allow loopback', interface: 'lo', protocol: :none) if new_resource.allow_loopback
      rules << default_firewall_rule('allow icmp', protocol: :icmp) if new_resource.allow_icmp
      rules << default_firewall_rule('established', stateful: [:related, :established], protocol: :none) if new_resource.allow_established
      rules << default_firewall_rule('ipv6_icmp', protocol: :'ipv6-icmp') if new_resource.ipv6_enabled && new_resource.allow_established
    end

    rules
  end

  def default_firewall_rule(name, overrides = {})
    default_firewall_rule_class.new({
      name: name,
      firewall_name: new_resource.name,
      command: :allow,
      protocol: :tcp,
      source: nil,
      source_port: nil,
      port: nil,
      dest_port: nil,
      destination: nil,
      position: 50,
      description: name,
      redirect_port: nil,
      zone: nil,
      direction: :in,
      logging: nil,
      interface: nil,
      dest_interface: nil,
      stateful: nil,
      include_comment: true,
      program: nil,
      service: nil,
      raw: nil,
    }.merge(overrides))
  end

  def default_firewall_rule_class
    @default_firewall_rule_class ||= Struct.new(
      :name,
      :firewall_name,
      :command,
      :protocol,
      :source,
      :source_port,
      :port,
      :dest_port,
      :destination,
      :position,
      :description,
      :redirect_port,
      :zone,
      :direction,
      :logging,
      :interface,
      :dest_interface,
      :stateful,
      :include_comment,
      :program,
      :service,
      :raw,
      keyword_init: true
    )
  end

  def nftables_rule_from_firewall_rule(firewall_rule)
    nftables_rule_class.new(
      command: nftables_command(firewall_rule.command),
      protocol: firewall_rule.protocol,
      direction: firewall_rule.direction,
      family: ipv6_rule?(firewall_rule) ? :ip6 : :ip,
      source: firewall_rule.source,
      sport: firewall_rule.source_port,
      interface: firewall_rule.interface,
      dport: dport_calc(firewall_rule),
      destination: firewall_rule.destination,
      outerface: firewall_rule.dest_interface,
      position: firewall_rule.position,
      stateful: firewall_rule.stateful,
      redirect_port: firewall_rule.redirect_port,
      description: firewall_rule.description,
      include_comment: firewall_rule.include_comment,
      log_prefix: nil,
      log_group: nil,
      raw: firewall_rule.raw
    )
  end

  def nftables_command(command)
    return :drop if command == :deny

    command == :allow ? :accept : command
  end

  def nftables_rule_class
    @nftables_rule_class ||= Struct.new(
      :command,
      :protocol,
      :direction,
      :family,
      :source,
      :sport,
      :interface,
      :dport,
      :destination,
      :outerface,
      :position,
      :stateful,
      :redirect_port,
      :description,
      :include_comment,
      :log_prefix,
      :log_group,
      :raw,
      keyword_init: true
    )
  end
end
