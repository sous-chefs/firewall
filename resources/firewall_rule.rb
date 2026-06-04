# frozen_string_literal: true

unified_mode true

# Common properties defined in a resource partial
use '_partial/_firewall_rule'

provides :firewall_rule

property :direction, Symbol, equal_to: [:in, :out, :pre, :post], default: :in
property :logging, Symbol, equal_to: [:connections, :packets]
property :interface, String
property :dest_interface, String
property :stateful, [Symbol, Array]
property :include_comment, [true, false], default: true

# only used for Windows Firewalls
property :program, String
property :service, String

# for when you just want to pass a raw rule
property :raw, String

# do you want this rule to notify the backend to recalculate
# (and potentially reapply) the firewall_rule(s) it finds?
property :notify_firewall, [true, false], default: true

action :create do
  firewall_resource = Chef.run_context.resource_collection.find(firewall: new_resource.firewall_name)
  raise 'could not find a firewall resource' unless firewall_resource

  return unless new_resource.notify_firewall

  case firewall_backend(firewall_resource)
  when :firewalld
    create_firewalld_rule
  when :nftables
    create_nftables_rule
  when :iptables
    create_iptables_rule
  when :ufw
    create_ufw_rule
  when :windows
    create_windows_firewall_rule
  else
    raise "Unsupported firewall backend #{firewall_backend(firewall_resource)}"
  end
end

action_class do
  include FirewallCookbook::Helpers

  def firewall_backend(firewall_resource)
    firewall_resource.backend || default_firewall_backend
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

  def create_iptables_rule
    with_run_context :root do
      iptables_rule new_resource.description do
        apply_common_rule_properties(self)
      end
    end
  end

  def create_ufw_rule
    with_run_context :root do
      ufw_rule new_resource.description do
        apply_common_rule_properties(self)
      end
    end
  end

  def create_windows_firewall_rule
    with_run_context :root do
      windows_firewall_rule new_resource.description do
        apply_common_rule_properties(self)
      end
    end
  end

  def create_nftables_rule
    with_run_context :root do
      nftables_rule new_resource.description do
        firewall_name new_resource.firewall_name
        command new_resource.command
        protocol new_resource.protocol
        direction new_resource.direction
        family ipv6_rule?(new_resource) ? :ip6 : :ip
        source new_resource.source if new_resource.property_is_set?(:source)
        sport new_resource.source_port if new_resource.property_is_set?(:source_port)
        interface new_resource.interface if new_resource.property_is_set?(:interface)
        dport dport_calc(new_resource) if new_resource.property_is_set?(:port) || new_resource.property_is_set?(:dest_port)
        destination new_resource.destination if new_resource.property_is_set?(:destination)
        outerface new_resource.dest_interface if new_resource.property_is_set?(:dest_interface)
        position new_resource.position
        stateful new_resource.stateful if new_resource.property_is_set?(:stateful)
        redirect_port new_resource.redirect_port if new_resource.property_is_set?(:redirect_port)
        description new_resource.description
        include_comment new_resource.include_comment
        raw new_resource.raw if new_resource.property_is_set?(:raw)
      end
    end
  end

  def apply_common_rule_properties(rule)
    rule.firewall_name new_resource.firewall_name
    rule.command new_resource.command
    rule.protocol new_resource.protocol
    rule.source new_resource.source if new_resource.property_is_set?(:source)
    rule.source_port new_resource.source_port if new_resource.property_is_set?(:source_port)
    rule.port new_resource.port if new_resource.property_is_set?(:port)
    rule.dest_port new_resource.dest_port if new_resource.property_is_set?(:dest_port)
    rule.destination new_resource.destination if new_resource.property_is_set?(:destination)
    rule.position new_resource.position
    rule.description new_resource.description
    rule.redirect_port new_resource.redirect_port if new_resource.property_is_set?(:redirect_port)
    rule.direction new_resource.direction
    rule.logging new_resource.logging if new_resource.property_is_set?(:logging)
    rule.interface new_resource.interface if new_resource.property_is_set?(:interface)
    rule.dest_interface new_resource.dest_interface if new_resource.property_is_set?(:dest_interface)
    rule.stateful new_resource.stateful if new_resource.property_is_set?(:stateful)
    rule.include_comment new_resource.include_comment
    rule.program new_resource.program if new_resource.property_is_set?(:program)
    rule.service new_resource.service if new_resource.property_is_set?(:service)
    rule.raw new_resource.raw if new_resource.property_is_set?(:raw)
  end

  def create_firewalld_rule
    with_run_context :root do
      firewalld_rule new_resource.description do
        firewall_name new_resource.firewall_name
        command new_resource.command
        protocol new_resource.protocol
        source new_resource.source if new_resource.property_is_set?(:source)
        source_port new_resource.source_port if new_resource.property_is_set?(:source_port)
        port new_resource.port if new_resource.property_is_set?(:port)
        dest_port new_resource.dest_port if new_resource.property_is_set?(:dest_port)
        destination new_resource.destination if new_resource.property_is_set?(:destination)
        position new_resource.position
        description new_resource.description
        redirect_port new_resource.redirect_port if new_resource.property_is_set?(:redirect_port)
        zone new_resource.zone if new_resource.property_is_set?(:zone)
        include_comment new_resource.include_comment
        raw new_resource.raw if new_resource.property_is_set?(:raw)
        notify_firewall new_resource.notify_firewall
      end
    end
  end
end
