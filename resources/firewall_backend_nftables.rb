# frozen_string_literal: true

provides :firewall_backend_nftables, os: 'linux'
unified_mode true
use '_partial/_firewall'

action :install do
  check_platform!
  package 'nftables' do
    options new_resource.package_options if new_resource.package_options
  end
end

%i(restart reload flush).each do |operation|
  action operation do
    check_platform!
    family = new_resource.ipv6_enabled ? :inet : :ip
    desired = new_resource.rules.dup
    if family == :ip && (!desired.empty? || new_resource.rule_resources.any?(&:raw))
      raise ArgumentError, 'IPv4-only nftables requires structured rules'
    end
    new_resource.rule_resources.each do |rule|
      desired[build_firewall_rule(native_rule(rule), filter_family: family)] = rule.position
    end

    nftables new_resource.name do
      rules desired
      filter_family family
      input_policy new_resource.input_policy.downcase
      output_policy new_resource.output_policy.downcase
      forward_policy new_resource.forward_policy.downcase
      table_ip_nat true
      table_ip6_nat new_resource.ipv6_enabled
      reload_on_rebuild true
      action :rebuild
    end
  end
end

%i(disable delete).each do |operation|
  action operation do
    check_platform!
    nftables new_resource.name do
      reload_on_rebuild true
      action operation
    end
  end
end

action_class do
  include FirewallCookbook::Helpers::Nftables

  def check_platform!
    return if platform_family?('debian', 'rhel')

    raise ArgumentError, 'The nftables backend requires a Debian or RHEL family distribution'
  end

  def native_rule(rule)
    check_properties!(rule)
    selected_protocol = nftables_protocol(rule)
    build_resource(:nftables_rule, rule.name) do
      %i(command source destination direction interface stateful redirect_port description
         include_comment log_prefix log_group raw).each do |property|
        value = rule.public_send(property)
        public_send(property, value) unless value.nil?
      end
      protocol selected_protocol
      sport rule.source_port if rule.source_port
      dport(rule.dest_port || rule.port) if rule.dest_port || rule.port
      outerface rule.dest_interface if rule.dest_interface
    end
  end

  def check_properties!(rule)
    unsupported = %i(zone logging program service).select { |property| rule.property_is_set?(property) }
    raise ArgumentError, "Unsupported nftables rule properties: #{unsupported.join(', ')}" unless unsupported.empty?

    commands = Array(rule.command)
    unless !commands.empty? && commands.all? { |command| FirewallCookbook::Helpers::Nftables::TARGET.key?(command) }
      raise ArgumentError, "Unsupported nftables rule command: #{rule.command.inspect}"
    end
    if !commands.include?(:log) && (rule.property_is_set?(:log_prefix) || rule.property_is_set?(:log_group))
      raise ArgumentError, 'log_prefix and log_group require the nftables log command'
    end
    if rule.property_is_set?(:redirect_port) && !commands.include?(:redirect)
      raise ArgumentError, 'redirect_port requires the nftables redirect command'
    end
    return unless rule.raw

    matches = %i(command protocol source source_port port dest_port destination direction interface
                 dest_interface stateful redirect_port include_comment log_prefix log_group)
    if matches.any? { |property| rule.property_is_set?(property) }
      raise ArgumentError, 'A raw nftables rule cannot be combined with structured rule properties'
    end
  end

  def nftables_protocol(rule)
    transport = { 6 => :tcp, 17 => :udp }
    unless rule.source_port || rule.dest_port || rule.port
      return transport.key(rule.protocol) || rule.protocol
    end

    protocol = transport.fetch(rule.protocol, rule.protocol)
    raise ArgumentError, 'Ports require TCP or UDP on the nftables backend' unless transport.value?(protocol)

    protocol
  end
end
