# frozen_string_literal: true

require 'shellwords'

module FirewallCookbook
  module Helpers
    module FirewalldDBus
      def firewalld(system_bus)
        system_bus['org.fedoraproject.FirewallD1']
      end

      def firewalld_object(system_bus)
        firewalld(system_bus)['/org/fedoraproject/FirewallD1']
      end

      def firewalld_interface(system_bus)
        firewalld_object(system_bus)['org.fedoraproject.FirewallD1']
      end

      def get_default_zone(system_bus)
        firewalld_interface(system_bus).getDefaultZone
      end

      def get_firewalld_version(system_bus)
        firewalld_interface(system_bus)['version']
      end

      def get_log_denied(system_bus)
        firewalld_interface(system_bus).getLogDenied
      end

      def config_object(system_bus)
        firewalld(system_bus)['/org/fedoraproject/FirewallD1/config']
      end

      def config_interface(system_bus)
        config_object(system_bus)['org.fedoraproject.FirewallD1.config']
      end

      def icmptype_interface(dbus, icmptype_path)
        icmptype_object = firewalld(dbus)[icmptype_path]
        icmptype_object['org.fedoraproject.FirewallD1.config.icmptype']
      end

      def ipset_interface(dbus, ipset_path)
        ipset_object = firewalld(dbus)[ipset_path]
        ipset_object['org.fedoraproject.FirewallD1.config.ipset']
      end

      def helper_interface(dbus, helper_path)
        helper_object = firewalld(dbus)[helper_path]
        helper_object['org.fedoraproject.FirewallD1.config.helper']
      end

      def service_interface(dbus, service_path)
        service_object = firewalld(dbus)[service_path]
        service_object['org.fedoraproject.FirewallD1.config.service']
      end

      def policy_interface(dbus, policy_path)
        policy_object = firewalld(dbus)[policy_path]
        policy_object['org.fedoraproject.FirewallD1.config.policy']
      end

      def zone_interface(dbus, zone_path)
        zone_object = firewalld(dbus)[zone_path]
        zone_object['org.fedoraproject.FirewallD1.config.zone']
      end

      def delete_dbus_object(type, interface_type)
        dbus = DBus.system_bus
        config = config_interface(dbus)
        return unless config.public_send("get#{type}Names").include?(new_resource.short)

        path = config.public_send("get#{type}ByName", new_resource.short)
        object = firewalld(dbus)[path]["org.fedoraproject.FirewallD1.config.#{interface_type}"]
        converge_by("Delete #{type} #{new_resource.short}") do
          object.remove
          firewalld_interface(dbus).reload
        end
      end

      def normalise_dbus_value(key, value)
        case key.to_s
        when 'ports', 'source_ports'
          value.map { |port| port.join('/') }
        when 'forward_ports'
          value.map do |port, protocol, target_port, address|
            result = "port=#{port}:proto=#{protocol}"
            result << ":toport=#{target_port}" unless target_port.empty?
            result << ":toaddr=#{address}" unless address.empty?
            result
          end
        else
          value
        end
      end

      def same_rich_rules?(current, desired)
        desired && current.map { |rule| Shellwords.split(rule) }.sort == desired.map { |rule| Shellwords.split(rule) }.sort
      end

      # port=portid[-portid]:proto=protocol[:toport=portid[-portid]][:toaddr=address[/mask]]
      def parse_forward_ports(forward_ports)
        match = forward_ports.match(/\Aport=([^:]+):proto=([^:]+)(?::toport=([^:]*))?(?::toaddr=(.+))?\z/)
        raise ArgumentError, "Invalid forward port: #{forward_ports}" unless match

        match.captures.map { |value| value || '' }
      end

      def forward_ports_to_dbus(new_resource)
        fwp = new_resource.forward_ports.map do |e|
          parse_forward_ports(e)
        end
        DBus.variant('a(ssss)', fwp)
      end
    end
  end
end
