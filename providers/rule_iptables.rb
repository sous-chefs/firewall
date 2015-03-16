#
# Author:: Ronald Doorn (<rdoorn@schubergphilis.com>)
# Cookbook Name:: firwall
# Provider:: rule_iptables
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
  if rule_exists?('ACCEPT')
    Chef::Log.debug "Rule #{@new_resource.description} already allowed - skipping"
  else
    converge_by("Allowing #{@new_resource.description}") do
      apply_rule('ACCEPT')
    end
  end
end

action :deny do
  if rule_exists?('DROP')
    Chef::Log.debug "Rule #{@new_resource.description} already denied - skipping"
  else
    converge_by("Denying #{@new_resource.description}") do
      apply_rule('DROP')
    end
  end
end

action :reject do
  if rule_exists?('REJECT')
    Chef::Log.debug "Rule #{@new_resource.description} already rejected - skipping"
  else
    converge_by("Rejecting #{@new_resource.description}") do
      apply_rule('REJECT')
    end
  end
end

action :log do
  if rule_exists?("LOG --log-prefix \"iptables #{@new_resource.name}: \" --log-level 7")
    Chef::Log.debug "Rule #{@new_resource.description} already logged - skipping"
  else
    converge_by("Logging #{@new_resource.description}") do
      apply_rule("LOG --log-prefix \"iptables #{@new_resource.name}: \" --log-level 7")
    end
  end
end

action :remove do
  if !rule_exists?
    Chef::Log.debug "Rule #{@new_resource.description} already removed - skipping"
  else
    converge_by("Removing #{@new_resource.description}") do
      remove_rule()
    end
  end
end

private

# iptables -A INPUT -p tcp -m tcp --dport 22 -s 192.168.0.4 -j ACCEPT
# iptables -A INPUT -p tcp -m tcp -s 10.0.0.0/8 -d 192.168.0.1 -j DROP
# iptables -I INPUT 1 -p tcp -m tcp -s 10.0.0.0/8 -d 192.168.0.1 -j DROP
def apply_rule(type = nil) # rubocop:disable MethodLength
  iptables_command = 'iptables '

  if @new_resource.raw
    iptables_command << @new_resource.raw
  else
    iptables_command << "#{action(:add)} "
    iptables_command << "#{rule} "
    iptables_command << "-j #{type}"
  end

  Chef::Log.debug("iptables add: #{iptables_command}")
  shell_out!(iptables_command)

  Chef::Log.info("#{@new_resource} #{type} rule added")
  new_resource.updated_by_last_action(true)
end

def remove_rule(type = nil) # rubocop:disable MethodLength
  iptables_command = 'iptables '
  if @new_resource.raw
    @new_resource.raw[1] = 'D'
    iptables_command << @new_resource.raw
  else
    iptables_command << "#{action(:remove)} "
    iptables_command << "#{rule} "
    iptables_command << "-j #{type}"
  end

  Chef::Log.debug("iptables remove: #{iptables_command}")
  shell_out!(iptables_command)
  new_resource.updated_by_last_action(true)
end

def chain
  chain=@new_resource.direction.to_s
  { "in" => "INPUT", "out" => "OUTPUT" }.each { |k, v| chain.sub!(k, v) }  
  return chain
end

def action(type = nil)
  case type
  when :add
    Chef::Log.debug("iptables action: ADD")
    return "-I #{chain} #{@new_resource.position}" if @new_resource.position
    return "-A #{chain}"
  when :remove
    Chef::Log.debug("iptables action: Remove")
    return "-D #{chain}"
  when :detect
    Chef::Log.debug("iptables action: Detect")
    return "#{@new_resource.position} -A #{chain}" if @new_resource.position
    return "\\d+ -A #{chain}"
  end
end

def rule
  rule = ''
  if (chain == 'OUTPUT') 
    rule << "-o #{@new_resource.interface} " if @new_resource.interface
  else
    rule << "-i #{@new_resource.interface} " if @new_resource.interface
  end
  
  rule << "-p #{@new_resource.protocol ? @new_resource.protocol : 'tcp'} "
  rule << "-m #{@new_resource.protocol ? @new_resource.protocol : 'tcp'} " if @new_resource.protocol == :tcp || !@new_resource.protocol

  if @new_resource.port
    rule << "--sport #{@new_resource.port} "
  elsif @new_resource.ports
    rule << "-m multiport --sports #{@new_resource.ports.join(',').gsub!('-',':')} "
  elsif @new_resource.port_range
    rule << "-m multiport --sports #{@new_resource.port_range.first}:#{@new_resource.port_range.last} "
  end
  
  if @new_resource.source
    rule << "-s #{@new_resource.source} "
  end
  if @new_resource.destination
    rule << "-d #{@new_resource.destination} "
  end

  if @new_resource.dest_port
    rule << "--dport #{@new_resource.dest_port} "
  elsif @new_resource.dest_ports
    rule << "-m multiport --dports #{@new_resource.dest_ports.join(',').gsub('-',':')} "
  end
  
  if @new_resource.state
    if @new_resource.state.kind_of?(Array)
      rule << "-m state --state #{@new_resource.state.join(',').upcase} "
    elsif @new_resource.state.kind_of?(Symbol)
      rule << "-m state --state #{@new_resource.state.upcase} " if @new_resource.state
    end
  end
  
  rule << "-m comment --comment \"#{@new_resource.description}\" "

  rule.strip
end

# TODO: currently only works when firewall is enabled
def rule_exists?(type = nil)
  # -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
  # -A INPUT -p tcp -m state --state NEW -m tcp --dport 22 -j ACCEPT
  # -A INPUT -p udp -m multiport --dports 67:68,66,65 -j ACCEPT
  
  iptables = ''
  if @new_resource.raw
    iptables << @new_resource.raw
  else
    iptables << "#{action(:detect)} "
    iptables << "#{rule} "
    if type
  	  iptables << "-j #{type}"
    else
	  # FIXME - needs better logic
  	  iptables << "-j (ALLOW|DENY|REJECT)"
    end
  end

  # used by Zap provider
  @new_resource.zap = iptables

  line_number=0;
  match = shell_out!("iptables -S #{chain}").stdout.lines.find do |line|
    next if line[1] == 'P'
    line_number += 1
    line = "#{line_number} #{line}"
    Chef::Log.debug("matching: [#{iptables}] to [#{line.chomp.rstrip}] => #{iptables == line.chomp.rstrip}") 
    line.chomp.rstrip =~ /#{iptables.rstrip}/
  end

  Chef::Log.debug("iptables: found existing rule for \"#{rule}\": \"#{match.strip}\"") if match

  !!match
end
