module FirewallCookbook
  module Helpers
    def dport_calc(new_resource)
      new_resource.dest_port || new_resource.port
    end

    def port_to_s(p)
      if p.is_a?(String)
        p
      elsif p && p.is_a?(Integer)
        p.to_s
      elsif p && p.is_a?(Array)
        p.map! { |o| port_to_s(o) }
        p.sort.join(',')
      elsif p && p.is_a?(Range)
        if platform_family?('windows')
          "#{p.first}-#{p.last}"
        else
          "#{p.first}:#{p.last}"
        end
      end
    end

    def ipv6_enabled?(new_resource)
      new_resource.ipv6_enabled
    end

    def disabled?(new_resource)
      # if either flag is found in the non-default boolean state
      disable_flag = !(new_resource.enabled && !new_resource.disabled)

      Chef::Log.warn("#{new_resource} has been disabled, not proceeding") if disable_flag
      disable_flag
    end

    def ip_with_mask(new_resource, ip)
      if ip.include?('/')
        ip
      elsif new_resource.ipversion == :ipv4
        "#{ip}/32"
      elsif new_resource.ipversion == :ipv6
        "#{ip}/128"
      else
        ip
      end
    end

    def ubuntu?(current_node)
      current_node['platform'] == 'ubuntu'
    end
  end
end
