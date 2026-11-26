# frozen_string_literal: true

require 'chef/mixin/template'
require 'fileutils'
require 'shellwords'
require 'tmpdir'

module FirewallCookbook
  module Helpers
    module Ufw
      include FirewallCookbook::Helpers
      include Chef::Mixin::ShellOut

      def ufw_rules_filename
        '/etc/default/ufw-chef.rules'
      end

      def ufw_active?
        cmd = shell_out!('ufw', 'status')
        cmd.stdout =~ /^Status:\sactive/
      end

      def ufw_disable!
        shell_out!('ufw', 'disable', input: 'yes')
      end

      def ufw_enable!
        shell_out!('ufw', 'enable', input: 'yes')
      end

      def ufw_reset!
        shell_out!('ufw', 'reset', input: 'yes')
      end

      def ufw_logging!(param)
        shell_out!('ufw', 'logging', param.to_s)
      end

      def ufw_rule!(cmd)
        shell_out!(*Shellwords.split(cmd), input: 'yes')
      end

      def ufw_transaction
        # UFW reset replaces all six rule files. Logging and startup state are in ufw.conf.
        files = %w(
          /etc/ufw/before.rules /etc/ufw/before6.rules
          /etc/ufw/after.rules /etc/ufw/after6.rules
          /etc/ufw/user.rules /etc/ufw/user6.rules
          /etc/ufw/ufw.conf /etc/default/ufw
        )
        was_active = ufw_active?

        snapshots = {}
        keep_snapshots = false
        begin
          files.each do |path|
            parent = ::File.dirname(path)
            snapshots[parent] ||= Dir.mktmpdir('.chef-ufw-', parent)
            backup = ::File.join(snapshots.fetch(parent), ::File.basename(path))
            ::FileUtils.copy_entry(path, backup, true) if ::File.exist?(path) || ::File.symlink?(path)
          end

          begin
            yield
          rescue StandardError
            begin
              files.each do |path|
                snapshot = snapshots.fetch(::File.dirname(path))
                backup = ::File.join(snapshot, ::File.basename(path))
                if ::File.exist?(backup) || ::File.symlink?(backup)
                  # Stage on the destination filesystem and retain the original backup until rollback completes.
                  replacement = "#{backup}.restore"
                  ::FileUtils.copy_entry(backup, replacement, true)
                  ::File.rename(replacement, path)
                else
                  ::FileUtils.rm_f(path)
                end
              end
              if was_active
                shell_out!('ufw', 'reload')
              else
                ufw_disable!
              end
            rescue StandardError => error
              keep_snapshots = true
              Chef::Log.error("Could not restore the previous UFW rules: #{error}. Backups: #{snapshots.values.join(', ')}")
            end
            raise
          end
        ensure
          snapshots.each_value { |snapshot| ::FileUtils.remove_entry(snapshot) } unless keep_snapshots
        end
      end

      def ufw_replay!(desired, log_level)
        ufw_reset!
        ufw_logging!(log_level)
        desired.sort_by { |_rule, position| position }.each { |rule, _position| ufw_rule!(rule) }
        ufw_enable! unless ufw_active?
      end

      def build_rule(new_resource)
        Chef::Log.info("#{new_resource.name} apply_rule #{new_resource.command}")

        # if we don't do this, we may see some bugs where traffic is opened on all ports to all hosts when only RELATED,ESTABLISHED was intended
        if new_resource.stateful
          msg = +''
          msg << "firewall_rule[#{new_resource.name}] was asked to "
          msg << "#{new_resource.command} a stateful rule using #{new_resource.stateful} "
          msg << 'but ufw does not support this kind of rule. Consider guarding by platform_family.'
          raise msg
        end

        # if we don't do this, ufw will fail as it does not support protocol numbers, so we'll only allow it to run if specifying icmp/tcp/udp protocol types
        if new_resource.protocol && !new_resource.protocol.to_s.downcase.match('^(tcp|udp|esp|ah|ipv6|none)$')
          msg = +''
          msg << "firewall_rule[#{new_resource.name}] was asked to "
          msg << "#{new_resource.command} a rule using protocol #{new_resource.protocol} "
          msg << 'but ufw does not support this kind of rule. Consider guarding by platform_family.'
          raise msg
        end

        # some examples:
        # ufw allow from 192.168.0.4 to any port 22
        # ufw deny proto tcp from 10.0.0.0/8 to 192.168.0.1 port 25
        # ufw insert 1 allow proto tcp from 0.0.0.0/0 to 192.168.0.1 port 25

        if new_resource.raw
          "ufw #{new_resource.raw.strip}"
        else
          "ufw #{rule(new_resource)}"
        end
      end

      def rule(new_resource)
        rule = +''
        rule << "#{new_resource.command} "
        rule << rule_interface(new_resource)
        rule << rule_logging(new_resource)
        rule << rule_proto(new_resource)
        rule << rule_dest_port(new_resource)
        rule << rule_source_port(new_resource)
        rule << rule_description(new_resource)
        rule = rule.strip

        if rule == 'ufw allow in proto tcp to any from any'
          Chef::Log.warn("firewall_rule[#{new_resource.name}] produced a rule that opens all traffic. This may be a logic error in your cookbook.")
        end

        rule
      end

      def rule_interface(new_resource)
        rule = +''
        rule << "#{new_resource.direction} " if new_resource.direction
        rule << "on #{new_resource.interface} " if new_resource.interface && new_resource.direction
        rule << "in on #{new_resource.interface} " if new_resource.interface && !new_resource.direction
        rule
      end

      def rule_proto(new_resource)
        rule = +''
        rule << "proto #{new_resource.protocol} " if new_resource.protocol && new_resource.protocol.to_s.to_sym != :none
        rule
      end

      def rule_description(new_resource)
        rule = +''
        rule << "comment \"#{new_resource.description}\" " if new_resource.description && new_resource.include_comment
        rule
      end

      def port_to_s(ports)
        return super unless ports.is_a?(Array)

        ports.map { |port| port_to_s(port) }.sort_by { |port| [port.to_i, port] }.join(',')
      end

      def rule_dest_port(new_resource)
        rule = if new_resource.destination
                 "to #{new_resource.destination} "
               else
                 +'to any '
               end
        rule << "port #{port_to_s(dport_calc(new_resource))} " if dport_calc(new_resource)
        rule
      end

      def rule_source_port(new_resource)
        rule = if new_resource.source
                 "from #{new_resource.source} "
               else
                 +'from any '
               end

        if new_resource.source_port
          rule << "port #{port_to_s(new_resource.source_port)} "
        end
        rule
      end

      def rule_logging(new_resource)
        case new_resource.logging && new_resource.logging.to_sym
        when :connections
          'log '
        when :packets
          'log-all '
        else
          ''
        end
      end
    end
  end
end
