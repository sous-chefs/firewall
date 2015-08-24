#
# Author:: Sander van Harmelen (<svanharmelen@schubergphilis.com>)
# Cookbook Name:: firewall
# Provider:: rule_windows
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
require 'poise'

class Chef
  class Provider::FirewallRuleWindows < Provider
    include Poise
    include Chef::Mixin::ShellOut
    include FirewallCookbook::Helpers

    def action_allow
      apply_rule(:allow)
    end

    def action_deny
      apply_rule(:block)
    end

    def action_remove
      remove_rule()
    end

    private

    def apply_rule(type)
      if not rule_exists?(new_resource.name)
        converge_by("add '#{new_resource.name}' firewall rule") do
          notifying_block do
            parameters = rule_parameters(type).map{|k,v| "#{k}=#{v}"}.join(' ')
            shell_out!("netsh advfirewall firewall add rule name=\"#{new_resource.name}\" #{parameters}")
            new_resource.updated_by_last_action(true)
          end
        end
      elsif not rule_up_to_date?(new_resource.name, type)
        converge_by("update '#{new_resource.name}' firewall rule") do
          notifying_block do
            parameters = rule_parameters(type).map{|k,v| "#{k}=#{v}"}.join(' ')
            shell_out!("netsh advfirewall firewall set rule name=\"#{new_resource.name}\" new #{parameters}")
            new_resource.updated_by_last_action(true)
          end
        end
      else
        Chef::Log.info("firewall rule '#{new_resource.name}' already exists, skipping")
      end
    end

    def remove_rule()
      if rule_exists?(new_resource.name)
        converge_by("delete '#{new_resource.name}' firewall rule") do
          notifying_block do
            shell_out!("netsh advfirewall firewall delete rule name=\"#{new_resource.name}\"")
            new_resource.updated_by_last_action(true)
          end
        end
      else
        Chef::Log.info("firewall rule '#{new_resource.name}' does not exist, skipping")
      end
    end

    def rule_parameters(type)
      @rule_parameters ||= begin
        parameters = {}

        parameters['description'] = "\"#{new_resource.description}\""
        parameters['dir'] = new_resource.direction

        parameters['program'] = new_resource.program ? new_resource.program : 'any'
        parameters['service'] = new_resource.service ? new_resource.service : 'any'
        parameters['protocol'] = new_resource.protocol

        if new_resource.direction.to_sym == :out
          parameters['localip'] = new_resource.source ? new_resource.source : 'any'
          parameters['localport'] = port_to_s(new_resource.source_port) ? new_resource.source_port : 'any'
          parameters['interfacetype'] = new_resource.source_interface ? new_resource.source_interface : 'any'
          parameters['remoteip'] = new_resource.destination ? new_resource.destination : 'any'
          parameters['remoteport'] = port_to_s(new_resource.dest_port) ? new_resource.dest_port : 'any'
        else
          parameters['localip'] = new_resource.destination ? new_resource.destination : 'any'
          parameters['localport'] = port_to_s(new_resource.dest_port) ? new_resource.dest_port : 'any'
          parameters['interfacetype'] = new_resource.dest_interface ? new_resource.dest_interface : 'any'
          parameters['remoteip'] = new_resource.source ? new_resource.source : 'any'
          parameters['remoteport'] = port_to_s(new_resource.source_port) ? new_resource.source_port : 'any'
        end

        parameters['action'] = type.to_s

        parameters
      end
    end

    def rule_exists?(name)
      @exists ||= begin
        cmd = shell_out!("netsh advfirewall firewall show rule name=\"#{name}\"", :returns => [0, 1])
        cmd.stdout !~ /^No rules match the specified criteria/
      end
    end

    def rule_up_to_date?(name, type)
      @up_to_date ||= begin
        desired_parameters = rule_parameters(type)
        current_parameters = {}

        cmd = shell_out!("netsh advfirewall firewall show rule name=\"#{name}\" verbose")
        cmd.stdout.each_line do |line|
          current_parameters['description'] = "\"#{$1.chomp}\"" if line =~ /^Description:\s+(.*)$/
          current_parameters['dir'] = $1.chomp if line =~ /^Direction:\s+(.*)$/
          current_parameters['program'] = $1.chomp if line =~ /^Program:\s+(.*)$/
          current_parameters['service'] = $1.chomp if line =~ /^Service:\s+(.*)$/
          current_parameters['protocol'] = $1.chomp if line =~ /^Protocol:\s+(.*)$/
          current_parameters['localip'] = $1.chomp if line =~ /^LocalIP:\s+(.*)$/
          current_parameters['localport'] = $1.chomp if line =~ /^LocalPort:\s+(.*)$/
          current_parameters['interfacetype'] = $1.chomp if line =~ /^InterfaceTypes:\s+(.*)$/
          current_parameters['remoteip'] = $1.chomp if line =~ /^RemoteIP:\s+(.*)$/
          current_parameters['remoteport'] = $1.chomp if line =~ /^RemotePort:\s+(.*)$/
          current_parameters['action'] = $1.chomp if line =~ /^Action:\s+(.*)$/
        end

        up_to_date = true
        desired_parameters.each do |k,v|
          up_to_date = false if current_parameters[k] !~ /^["]?#{v}["]?$/i
        end

        up_to_date
      end
    end
  end
end
