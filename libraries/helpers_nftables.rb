module FirewallCookbook
  module Helpers
    module Nftables
      include FirewallCookbook::Helpers
      include Chef::Mixin::ShellOut

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
        firewall_rule << "oif #{rule_resource.dest_interface} " if rule_resource.dest_interface

        if rule_resource.source
          source_with_mask = ip_with_mask(rule_resource, rule_resource.source)
          Chef::Log.fatal source_with_mask
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
          firewall_rule << "#{rule_resource.protocol} sport #{port_to_s(rule_resource.source_port)} " if rule_resource.source_port
          firewall_rule << "#{rule_resource.protocol} dport #{port_to_s(dport_calc(rule_resource))} " if dport_calc(rule_resource)
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

      def log_nftables
        shell_out!('nft -n list ruleset')
      rescue Mixlib::ShellOut::ShellCommandFailed
        Chef::Log.info('log_nftables failed!')
      rescue Mixlib::ShellOut::CommandTimeout
        Chef::Log.info('log_nftables timed out!')
      end

      def nftables_flush!
        shell_out!('nft flush ruleset')
      end

      def nftables_default_allow!
        family = 'inet'
        shell_out!("#{cmd} add rule #{family} filter input ACCEPT")
        shell_out!("#{cmd} add rule #{family} filter output ACCEPT")
        shell_out!("#{cmd} add rule #{family} filter forward ACCEPT")
      end

      def default_ruleset(current_node)
        current_node['firewall']['nftables']['defaults'][:ruleset].to_h
      end

      def ensure_default_rules_exist(current_node, new_resource)
        input = new_resource.rules
        input ||= {}
        input.merge!(default_ruleset(current_node).to_h)
      end
    end
  end
end
