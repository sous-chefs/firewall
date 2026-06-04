# frozen_string_literal: true

unified_mode true

include FirewallCookbook::Helpers
include FirewallCookbook::Helpers::Nftables

provides :nftables,
         os: 'linux'

property :rules,
         Hash,
         default: {}
property :input_policy,
         String,
         equal_to: %w(drop accept),
         default: 'accept'
property :output_policy,
         String,
         equal_to: %w(drop accept),
         default: 'accept'
property :forward_policy,
         String,
         equal_to: %w(drop accept),
         default: 'accept'
property :table_ip_nat,
         [true, false],
         default: false
property :table_ip6_nat,
         [true, false],
         default: false
property :allow_ssh,
         [true, false],
         default: false
property :allow_mosh,
         [true, false],
         default: false
property :allow_winrm,
         [true, false],
         default: false
property :allow_loopback,
         [true, false],
         default: false
property :allow_icmp,
         [true, false],
         default: false
property :allow_established,
         [true, false],
         default: true
property :ipv6_enabled,
         [true, false],
         default: true
property :enabled,
         [true, false],
         default: true
property :log_level,
         Symbol,
         equal_to: [:low, :medium, :high, :full, :off],
         default: :low
property :package_options,
         String
property :nftables_conf_path, String,
         description: 'nftables.conf filepath',
         default: lazy { default_nftables_conf_path }

action :install do
  package 'nftables' do
    action :install
    notifies :rebuild, "nftables[#{new_resource.name}]"
  end
end

action :rebuild do
  rebuild_nftables
end

action :restart do
  service 'nftables' do
    action :restart
  end
end

action :reload do
  rebuild_nftables
end

action :disable do
  service 'nftables' do
    action [:disable, :stop]
  end
end

action :flush do
  rebuild_nftables
end

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Nftables

  def rebuild_nftables
    return unless new_resource.enabled

    ensure_default_rules_exist(new_resource)
    collect_nftables_rules

    file new_resource.nftables_conf_path do
      content <<~NFT
        #!/usr/sbin/nft -f
        flush ruleset
        #{build_rule_file(new_resource.rules)}
      NFT
      mode '0750'
      owner 'root'
      group 'root'
      notifies :restart, 'service[nftables]'
    end

    service 'nftables' do
      action [:enable, :start]
    end
  end

  def collect_nftables_rules
    collect_matching_rules(:nftables_rule).each do |firewall_rule|
      rule = build_firewall_rule(firewall_rule)
      new_resource.rules[rule] = firewall_rule.position
    end
  end

  def collect_matching_rules(resource_name)
    default_firewall_rules + Chef.run_context.resource_collection.select do |item|
      item.resource_name == resource_name &&
        item.firewall_name == new_resource.name &&
        item.notify_firewall &&
        item.action.include?(:create) &&
        !item.should_skip?(:create)
    end
  end

  def default_firewall_rules
    rules = []
    rules << default_firewall_rule('allow world to ssh', port: 22) if linux? && new_resource.allow_ssh
    rules << default_firewall_rule('allow world to mosh', protocol: :udp, port: 60000..61000) if linux? && new_resource.allow_mosh
    rules << default_firewall_rule('allow loopback', interface: 'lo', protocol: :none) if new_resource.allow_loopback
    rules << default_firewall_rule('allow icmp', protocol: :icmp) if new_resource.allow_icmp
    rules << default_firewall_rule('established', stateful: [:related, :established], protocol: :none) if new_resource.allow_established
    rules << default_firewall_rule('ipv6_icmp', protocol: :'ipv6-icmp') if new_resource.ipv6_enabled && new_resource.allow_established
    rules
  end

  def default_firewall_rule(name, overrides = {})
    default_firewall_rule_class.new({
      name: name,
      firewall_name: new_resource.name,
      command: :accept,
      protocol: :tcp,
      direction: :in,
      family: :ip,
      source: nil,
      sport: nil,
      interface: nil,
      dport: nil,
      destination: nil,
      outerface: nil,
      position: 50,
      stateful: nil,
      redirect_port: nil,
      description: name,
      include_comment: true,
      log_prefix: nil,
      log_group: nil,
      raw: nil,
      notify_firewall: true,
    }.merge(nftables_rule_overrides(overrides)))
  end

  def nftables_rule_overrides(overrides)
    mapped = overrides.dup
    mapped[:dport] = mapped.delete(:port) if mapped.key?(:port)
    mapped[:sport] = mapped.delete(:source_port) if mapped.key?(:source_port)
    mapped[:outerface] = mapped.delete(:dest_interface) if mapped.key?(:dest_interface)
    mapped[:command] = nftables_command(mapped[:command]) if mapped.key?(:command)
    mapped
  end

  def nftables_command(command)
    return :drop if command == :deny

    command == :allow ? :accept : command
  end

  def default_firewall_rule_class
    @default_firewall_rule_class ||= Struct.new(
      :name,
      :firewall_name,
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
      :notify_firewall,
      keyword_init: true
    )
  end
end
