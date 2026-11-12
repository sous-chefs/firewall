# frozen_string_literal: true

provides :firewall
unified_mode true
use '_partial/_firewall'

property :backend, Symbol, equal_to: %i(ufw iptables firewalld windows), default: lazy {
  case node['platform_family']
  when 'windows' then :windows
  when 'debian' then :ufw
  when 'amazon', 'fedora', 'rhel', 'suse' then :firewalld
  else :iptables
  end
}

default_action :install

%i(allow_ssh allow_winrm allow_mosh allow_loopback allow_icmp).each do |flag|
  property flag, [true, false], default: false
end
property :allow_established, [true, false], default: true

%i(install restart reload disable flush delete).each do |operation|
  action operation do
    next unless new_resource.enabled

    parent = new_resource
    public_send("firewall_backend_#{parent.backend}", parent.name) do
      %i(enabled log_level rules rule_resources ipv6_enabled
         package_options input_policy forward_policy output_policy ruleset ufw_defaults
         windows_input_policy windows_output_policy).each do |property|
        public_send(property, parent.public_send(property)) unless parent.public_send(property).nil?
      end
      action operation
    end

    if operation == :install
      defaults = []
      defaults << ['loopback', { interface: 'lo', protocol: :none }] if parent.allow_loopback && parent.backend == :iptables
      defaults << ['ssh', { port: 22, source: '0.0.0.0/0' }] if parent.allow_ssh && parent.backend != :windows
      defaults << ['winrm', { port: 5989, source: '0.0.0.0/0' }] if parent.allow_winrm && parent.backend == :windows
      defaults << ['mosh', { port: 60000..61000, protocol: :udp, source: '0.0.0.0/0' }] if parent.allow_mosh && parent.backend != :windows
      if parent.backend == :iptables
        defaults << ['icmp', { protocol: :icmp }] if parent.allow_icmp
        if parent.allow_established
          defaults << ['established', { protocol: :none, stateful: %i(related established) }]
          defaults << ['ipv6_icmp', { protocol: :'ipv6-icmp' }] if parent.ipv6_enabled
        end
      end
      defaults.each do |suffix, properties|
        firewall_rule "#{parent.name} #{suffix}" do
          firewall_name parent.name
          description({ 'loopback' => 'allow loopback', 'icmp' => 'allow icmp',
                        'ssh' => 'allow world to ssh', 'winrm' => 'allow world to winrm',
                        'mosh' => 'allow world to mosh' }.fetch(suffix, suffix))
          properties.each { |key, value| public_send(key, value) }
        end
      end
      # Rebuild even after the last declared rule has been removed.
      parent.delayed_action :restart unless parent.backend == :firewalld
    end
  end
end
