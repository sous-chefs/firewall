# frozen_string_literal: true

unified_mode true

use '_partial/_firewall'

provides :firewall

action :install do
  return if disabled?(new_resource)

  declare_backend_resource(:install)
end

action :restart do
  return if disabled?(new_resource)

  declare_backend_resource(:restart)
end

action :reload do
  return if disabled?(new_resource)

  declare_backend_resource(:reload)
end

action :disable do
  return if disabled?(new_resource)

  declare_backend_resource(:disable)
end

action :flush do
  return if disabled?(new_resource)

  declare_backend_resource(:flush)
end

action_class do
  include FirewallCookbook::Helpers

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

  def declare_backend_resource(requested_action)
    case firewall_backend
    when :firewalld
      firewalld new_resource.name do
        package_options new_resource.package_options if property_is_set?(:package_options)
        allow_ssh new_resource.allow_ssh
        allow_mosh new_resource.allow_mosh
        action requested_action
      end
    when :iptables
      iptables new_resource.name do
        copy_common_firewall_properties(self)
        iptables_ruleset new_resource.iptables_ruleset
        action requested_action
      end
    when :nftables
      nftables new_resource.name do
        copy_common_firewall_properties(self)
        input_policy 'drop'
        output_policy 'accept'
        forward_policy 'drop'
        table_ip_nat true
        table_ip6_nat new_resource.ipv6_enabled
        action nftables_action(requested_action)
      end
    when :ufw
      ufw new_resource.name do
        copy_common_firewall_properties(self)
        ufw_defaults new_resource.ufw_defaults
        action requested_action
      end
    when :windows
      windows_firewall new_resource.name do
        copy_common_firewall_properties(self)
        windows_policy new_resource.windows_policy
        action requested_action
      end
    else
      raise "Unsupported firewall backend #{firewall_backend}"
    end
  end

  def nftables_action(requested_action)
    requested_action == :restart ? :rebuild : requested_action
  end

  def copy_common_firewall_properties(resource)
    resource.enabled new_resource.enabled
    resource.log_level new_resource.log_level
    resource.rules new_resource.rules
    resource.ipv6_enabled new_resource.ipv6_enabled
    resource.package_options new_resource.package_options if property_is_set?(:package_options)
    resource.allow_ssh new_resource.allow_ssh
    resource.allow_winrm new_resource.allow_winrm
    resource.allow_mosh new_resource.allow_mosh
    resource.allow_loopback new_resource.allow_loopback
    resource.allow_icmp new_resource.allow_icmp
    resource.allow_established new_resource.allow_established
  end
end
