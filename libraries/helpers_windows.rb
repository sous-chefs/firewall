module FirewallCookbook
  module Helpers
    module Windows
      include FirewallCookbook::Helpers
      include Chef::Mixin::ShellOut

      def icmp?(protocol)
        [:icmp, :icmpv4, :icmpv6, 1, 58].any?(protocol)
      end

      def fixup_cidr(str)
        newstr = str.clone
        newstr.gsub!('0.0.0.0/0', 'any') if newstr.include?('0.0.0.0/0')
        newstr.gsub!('/0', '') if newstr.include?('/0')
        newstr
      end

      def windows_rules_filename
        "#{ENV['HOME']}/windows-chef.rules"
      end

      def active?
        @active ||= begin
          cmd = shell_out!('netsh advfirewall show currentprofile')
          cmd.stdout =~ /^State\sON/
        end
      end

      def enable!
        shell_out!('netsh advfirewall set currentprofile state on')
      end

      def disable!
        shell_out!('netsh advfirewall set currentprofile state off')
      end

      def reset!
        shell_out!('netsh advfirewall reset')
      end

      def add_rule!(params)
        shell_out!("netsh advfirewall #{params}")
      end

      def delete_all_rules!
        shell_out!('netsh advfirewall firewall delete rule name=all')
      end

      def to_type(new_resource)
        cmd = new_resource.command
        if cmd == :reject || cmd == :deny
          :block
        else
          :allow
        end
      end

      def build_rule(new_resource)
        type = to_type(new_resource)
        parameters = {}

        parameters['description'] = "\"#{new_resource.description}\""
        parameters['dir'] = new_resource.direction

        new_resource.program && parameters['program'] = new_resource.program
        new_resource.service && parameters['service'] = new_resource.service
        # Keep interface the same and handle windows specific changes here.
        parameters['protocol'] = case new_resource.protocol
                                 when :icmp then :icmpv4
                                 else new_resource.protocol
                                 end

        if new_resource.direction.to_sym == :out
          parameters['localip'] = new_resource.source ? fixup_cidr(new_resource.source) : 'any'
          parameters['interfacetype'] = new_resource.interface || 'any'
          parameters['remoteip'] = new_resource.destination ? fixup_cidr(new_resource.destination) : 'any'
        else
          parameters['localip'] = new_resource.destination || 'any'
          parameters['interfacetype'] = new_resource.dest_interface || 'any'
          parameters['remoteip'] = new_resource.source ? fixup_cidr(new_resource.source) : 'any'
        end

        unless icmp?(new_resource.protocol)
          parameters['localport'] = new_resource.source_port ? port_to_s(new_resource.source_port) : 'any'
          parameters['remoteport'] = new_resource.dest_port ? port_to_s(new_resource.dest_port) : 'any'
        end

        parameters['action'] = type.to_s

        partial_command = parameters.map { |k, v| "#{k}=#{v}" }.join(' ')
        "firewall add rule name=\"#{new_resource.name}\" #{partial_command}"
      end

      def rule_exists?(name)
        @exists ||= begin
          cmd = shell_out!("netsh advfirewall firewall show rule name=\"#{name}\"", returns: [0, 1])
          cmd.stdout !~ /^No rules match the specified criteria/
        end
      end

      def show_all_rules!
        cmd = shell_out!('netsh advfirewall firewall show rule name=all')
        cmd.stdout.each_line do |line|
          Chef::Log.warn(line)
        end
      end

      def rule_up_to_date?(name, type)
        @up_to_date ||= begin
          desired_parameters = rule_parameters(type)
          current_parameters = {}

          cmd = shell_out!("netsh advfirewall firewall show rule name=\"#{name}\" verbose")
          cmd.stdout.each_line do |line|
            current_parameters['description'] = "\"#{Regexp.last_match(1).chomp}\"" if line =~ /^Description:\s+(.*)$/
            current_parameters['dir'] = Regexp.last_match(1).chomp if line =~ /^Direction:\s+(.*)$/
            current_parameters['program'] = Regexp.last_match(1).chomp if line =~ /^Program:\s+(.*)$/
            current_parameters['service'] = Regexp.last_match(1).chomp if line =~ /^Service:\s+(.*)$/
            current_parameters['protocol'] = Regexp.last_match(1).chomp if line =~ /^Protocol:\s+(.*)$/
            current_parameters['localip'] = Regexp.last_match(1).chomp if line =~ /^LocalIP:\s+(.*)$/
            current_parameters['interfacetype'] = Regexp.last_match(1).chomp if line =~ /^InterfaceTypes:\s+(.*)$/
            current_parameters['remoteip'] = Regexp.last_match(1).chomp if line =~ /^RemoteIP:\s+(.*)$/
            unless icmp?(new_resource.protocol)
              current_parameters['localport'] = Regexp.last_match(1).chomp if line =~ /^LocalPort:\s+(.*)$/
              current_parameters['remoteport'] = Regexp.last_match(1).chomp if line =~ /^RemotePort:\s+(.*)$/
            end
            current_parameters['action'] = Regexp.last_match(1).chomp if line =~ /^Action:\s+(.*)$/
          end

          up_to_date = true
          desired_parameters.each do |k, v|
            up_to_date = false if current_parameters[k] !~ /^["]?#{v}["]?$/i
          end

          up_to_date
        end
      end
    end
  end
end
