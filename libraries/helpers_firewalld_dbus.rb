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

      # port=portid[-portid]:proto=protocol[:toport=portid[-portid]][:toaddr=address[/mask]]
      def parse_forward_ports(forward_ports)
        port_regex = %r{port=([\w-]+):proto=([\w]+)(:toport=([\w-]+)|)(:toaddr=([\d\./]+)|)}
        captures = forward_ports.match(port_regex).captures
        captures.delete_at(4)
        captures.delete_at(2)
        captures.map { |e| e || '' }
      end

      def forward_ports_to_dbus(new_resource)
        fwp = new_resource.forward_ports.map do |e|
          parse_forward_ports(e)
        end
        new_resource.forward_ports = fwp
        DBus.variant('a(ssss)', new_resource.forward_ports)
      end
    end
  end
end
