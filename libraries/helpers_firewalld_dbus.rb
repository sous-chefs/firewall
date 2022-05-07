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
    end
  end
end
