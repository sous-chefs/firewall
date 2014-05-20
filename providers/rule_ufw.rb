#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: firwall
# Provider:: rule_ufw
#
# Copyright:: 2011, Opscode, Inc.
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

def whyrun_supported?
  true
end

include Chef::Mixin::ShellOut

action :allow do
  if rule_exists?
    Chef::Log.debug "Rule #{rule} already allowed - skipping"
  else
    converge_by("Allowing #{rule}") do
      apply_rule('allow')
    end
  end
end

action :deny do
  if rule_exists?
    Chef::Log.debug "Rule #{rule} already denied - skipping"
  else
    converge_by("Denying #{rule}") do
      apply_rule('deny')
    end
  end
end

action :reject do
  if rule_exists?
    Chef::Log.debug "Rule #{rule} already rejected - skipping"
  else
    converge_by("Rejecting #{rule}") do
      apply_rule('reject')
    end
  end
end

private

# ufw allow from 192.168.0.4 to any port 22
# ufw deny proto tcp from 10.0.0.0/8 to 192.168.0.1 port 25
# ufw insert 1 allow proto tcp from 0.0.0.0/0 to 192.168.0.1 port 25
def apply_rule(type = nil) # rubocop:disable MethodLength
  ufw_command = 'ufw '
  ufw_command << "insert #{@new_resource.position} " if @new_resource.position
  ufw_command << "#{type} "
  ufw_command << "#{rule} "

  Chef::Log.debug("ufw: #{ufw_command}")
  shell_out!(ufw_command)

  Chef::Log.info("#{@new_resource} #{type} rule added")
  shell_out!('ufw status verbose') # purely for the Chef::Log.debug output
  new_resource.updated_by_last_action(true)
end

def logging
  case @new_resource.logging
  when :connections
    'log '
  when :packets
    'log-all '
  else
    ''
  end
end

def rule
  rule = ''
  rule << "#{@new_resource.direction} " if @new_resource.direction
  if @new_resource.interface
    if @new_resource.direction
      rule << "on #{@new_resource.interface} "
    else
      rule << "in on #{@new_resource.interface} "
    end
  end
  rule << logging
  rule << "proto #{@new_resource.protocol} " if @new_resource.protocol
  if @new_resource.source
    rule << "from #{@new_resource.source} "
  else
    rule << 'from any '
  end
  rule << "port #{@new_resource.dest_port} " if @new_resource.dest_port
  if @new_resource.destination
    rule << "to #{@new_resource.destination} "
  else
    rule << 'to any '
  end
  if @new_resource.port
    rule << "port #{@new_resource.port} "
  elsif @new_resource.ports
    rule << "port #{@new_resource.ports.join(',')} "
  elsif @new_resource.port_range
    rule << "port #{@new_resource.port_range.first}:#{@new_resource.port_range.last} "
  end
  rule.strip
end

# TODO: currently only works when firewall is enabled
def rule_exists?
  # To                         Action      From
  # --                         ------      ----
  # 22                         ALLOW       Anywhere
  # 192.168.0.1 25/tcp         DENY        10.0.0.0/8
  # 22                         ALLOW       Anywhere
  # 3309 on eth9               ALLOW       Anywhere
  # Anywhere                   ALLOW       Anywhere
  # 80                         ALLOW       Anywhere (log)
  # 8080                       DENY        192.168.1.0/24
  # 1.2.3.5 5469/udp           ALLOW       1.2.3.4 5469/udp
  # 3308                       ALLOW       OUT Anywhere on eth8

  to = ''
  to << "#{Regexp.escape(@new_resource.destination)}\s" if @new_resource.destination

  if @new_resource.protocol && @new_resource.port
    to << "#{Regexp.escape("#{@new_resource.port}/#{@new_resource.protocol}")}\s"
  elsif @new_resource.port
    to << "#{Regexp.escape("#{@new_resource.port}")}\s"
  end

  to << "Anywhere\s" if to.empty?

  action = @new_resource.action
  action = action.first if action.is_a?(Enumerable)
  action = "#{Regexp.escape(action.to_s.upcase)}\s"

  from = ''
  from << "#{Regexp.escape(@new_resource.source || 'Anywhere')}"

  if @new_resource.direction == :out
    regex = /^#{to}.*#{action}OUT\s.*#{from}.*$/
  else
    regex = /^#{to}.*#{action}.*#{from}.*$/
  end

  match = shell_out!('ufw status').stdout.lines.find do |line|
    # TODO: support IPv6
    return false if line =~ /\(v6\)$/
    line =~ regex
  end

  Chef::Log.debug("ufw: found existing rule for \"#{rule}\": \"#{match.strip}\"") if match

  !!match
end
