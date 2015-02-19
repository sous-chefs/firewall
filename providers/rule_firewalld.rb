#
# Author:: Ronald Doorn (<rdoorn@schubergphilis.com>)
# Cookbook Name:: firwall
# Provider:: rule_firewalld
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
  if rule_exists?("LOG --log-prefix 'iptables #{@new_resource.name}: ' --log-level 7")
    Chef::Log.debug "Rule #{@new_resource.description} already logged - skipping"
  else
    converge_by("Logging #{@new_resource.description}") do
      apply_rule("LOG --log-prefix 'iptables #{@new_resource.name}: ' --log-level 7")
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

# firewall-cmd --direct --get-all-chains
# firewall-cmd --direct --get-chains ipv4 filter -->  Get all chains added to table filter, in this case, as a space separated list. This option concerns only chains previously added with --direct
# firewall-cmd --direct --get-rules ipv4 filter INPUT  --> Get all rules added to chain INPUT in table filter as a newline separated list of the priority and arguments.
def apply_rule(type = nil) # rubocop:disable MethodLength
  firewalld_parameters = ''

  if @new_resource.raw
    firewalld_parameters << @new_resource.raw
  else
    firewalld_parameters << "#{action(:add, type)} "
    firewalld_parameters << "#{rule} "
    firewalld_parameters << "-j #{type}"
  end

  Chef::Log.debug("firewalld: #{firewalld_parameters}")
  exec_firewalld(firewalld_parameters)

  Chef::Log.info("#{@new_resource} #{type} rule added")
  new_resource.updated_by_last_action(true)
end

def remove_rule(type = nil) # rubocop:disable MethodLength
  firewalld_command = ''
  firewalld_command << "#{action(:remove)} "
  if @new_resource.raw
    firewalld_command << @new_resource.raw
  else
    firewalld_command << "#{rule} "
    firewalld_command << "-j #{type}"
  end

  Chef::Log.debug("firewalld remove: #{firewalld_command}")
  exec_firewalld(firewalld_command)
  new_resource.updated_by_last_action(true)
end

def exec_firewalld(param)
  firewalld_command = 'firewall-cmd --direct '
  # make the rule active now
  shell_out!("#{firewalld_command} #{param}")
  # save it to the config
  shell_out!("#{firewalld_command} --permanent #{param}")
end


def logging
  logging = ''
  case @new_resource.logging
  when :connections
    logging << "-m state --state NEW " if @new_resource.protocol == :tcp
  when :packets
  else
  end
  logging << "-j LOG --log-prefix 'firewalld: ' --log-level 7"
end

def chain
  chain=@new_resource.direction.to_s
  { "in" => "INPUT", "out" => "OUTPUT" }.each { |k, v| chain.sub!(k, v) }  
  return chain
end

def action(type = nil, target = nil)
  case type
  when :add
    return "--add-rule"
  when :remove
    return "--remove-rule"
  end
end

# Detect or Set rule
def rule(type = nil)
  rule = "ipv4 filter #{chain} #{@new_resource.position ? @new_resource.position : 1} "

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
  
  if type == :detect
    rule << "-m comment --comment '*#{@new_resource.description}'* "
  else
    rule << "-m comment --comment '#{@new_resource.description}' "
  end

  rule.strip
end

def rule_exists?(type = nil)
  # ipv4 filter INPUT 1 -i lo -j ACCEPT
  
  firewalld = ''
  if @new_resource.raw
    firewalld << @new_resource.raw
  else
    firewalld << "#{rule(:detect)} "
    if type
  	  firewalld << "-j #{type}"
    else
  	  firewalld << "-j (ALLOW|DENY|REJECT)"
    end
  end

  @new_resource.zap = firewalld

  match = shell_out!('firewall-cmd --direct --get-all-rules').stdout.lines.find do |line|
    Chef::Log.debug("matching: [#{firewalld.rstrip}] to [#{line.chomp.rstrip}]") 
    line.chomp.rstrip =~ /#{firewalld.rstrip}/
  end

  Chef::Log.debug("firewalld: found existing rule for \"#{rule}\": \"#{match.strip}\"") if match

  !!match
end

