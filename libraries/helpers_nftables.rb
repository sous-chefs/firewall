module FirewallCookbook
  module Helpers
    module Nftables
      include FirewallCookbook::Helpers

      unless defined? CHAIN
        CHAIN = {
          in: 'INPUT',
          out: 'OUTPUT',
          pre: 'PREROUTING',
          post: 'POSTROUTING',
          # nil => "FORWARD",
        }.freeze
      end

      unless defined? TARGET
        TARGET = {
          allow: 'accept',
          reject: 'reject',
          deny: 'drop',
          masquerade: 'masquerade',
          redirect: 'redirect',
          log: 'log prefix "nftables:" group 0',
        }.freeze
      end

      def port_to_s(ports)
        case ports
        when String
          ports
        when Integer
          ports.to_s
        when Array
          p_strings = ports.map { |o| port_to_s(o) }
          "{#{p_strings.sort.join(',')}}"
        when Range
          "#{ports.first}-#{ports.last}"
        else
          raise "unknown class of port definition: #{ports.class}"
        end
      end

      def build_firewall_rule(rule_resource)
        return rule_resource.raw.strip if rule_resource.raw

        ip = ipv6_rule?(rule_resource) ? 'ip6' : 'ip'
        table = if [:pre, :post].include?(rule_resource.direction)
                  'nat'
                else
                  'filter'
                end
        firewall_rule = if table == 'nat'
                          "add rule #{ip} #{table} "
                        else
                          "add rule inet #{table} "
                        end
        firewall_rule << "#{CHAIN.fetch(rule_resource.direction.to_sym, 'FORWARD')} "

        firewall_rule << "iif #{rule_resource.interface} " if rule_resource.interface
        firewall_rule << "oif #{rule_resource.outerface} " if rule_resource.outerface

        if rule_resource.source
          source_with_mask = ip_with_mask(rule_resource, rule_resource.source)
          if source_with_mask != '0.0.0.0/0' && source_with_mask != '::/128'
            firewall_rule << "#{ip} saddr #{source_with_mask} "
          end
        end
        firewall_rule << "#{ip} daddr #{rule_resource.destination} " if rule_resource.destination

        case rule_resource.protocol
        when :icmp
          firewall_rule << 'icmp type echo-request '
        when :'ipv6-icmp', :icmpv6
          firewall_rule << 'icmpv6 type { echo-request, nd-router-solicit, nd-neighbor-solicit, nd-router-advert, nd-neighbor-advert } '
        when :tcp, :udp
          firewall_rule << "#{rule_resource.protocol} sport #{port_to_s(rule_resource.sport)} " if rule_resource.sport
          firewall_rule << "#{rule_resource.protocol} dport #{port_to_s(rule_resource.dport)} " if rule_resource.dport
        when :esp, :ah
          firewall_rule << "#{ip} #{ip == 'ip6' ? 'nexthdr' : 'protocol'} #{rule_resource.protocol} "
        when :ipv6, :none
          # nothing to do
        end

        firewall_rule << "ct state #{Array(rule_resource.stateful).join(',').downcase} " if rule_resource.stateful
        firewall_rule << "#{TARGET[rule_resource.command.to_sym]} "
        firewall_rule << " to #{rule_resource.redirect_port} " if rule_resource.command == :redirect
        firewall_rule << "comment \"#{rule_resource.description}\" " if rule_resource.include_comment
        firewall_rule.strip!
        firewall_rule
      end

      def nftables_packages
        %w(nftables)
      end

      def default_ruleset(new_resource)
        rules = {
          'add table inet filter' => 1,
          "add chain inet filter INPUT { type filter hook input priority 0 ; policy #{new_resource.input_policy}; }" => 2,
          "add chain inet filter OUTPUT { type filter hook output priority 0 ; policy #{new_resource.output_policy}; }" => 2,
          "add chain inet filter FOWARD { type filter hook forward priority 0 ; policy #{new_resource.forward_policy}; }" => 2
        }
        if new_resource.table_ip_nat
          rules['add table ip nat'] = 1
          rules['add chain ip nat POSTROUTING { type nat hook postrouting priority 100 ;}'] = 2
          rules['add chain ip nat PREROUTING { type nat hook prerouting priority -100 ;}'] = 2
        end
        if new_resource.table_ip6_nat
          rules['add table ip6 nat'] = 1
          rules['add chain ip6 nat POSTROUTING { type nat hook postrouting priority 100 ;}'] = 2
          rules['add chain ip6 nat PREROUTING { type nat hook prerouting priority -100 ;}'] = 2
        end
        rules
      end

      def ensure_default_rules_exist(new_resource)
        input = new_resource.rules || {}
        input.merge!(default_ruleset(new_resource))
      end
    end
  end
end
