#
# Cookbook Name:: firewall
# Provider:: rule_iptables
#
# Copyright 2012, computerlyrik
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
include Chef::Mixin::ShellOut

action :allow do
  apply_rule('allow')
end

action :deny do
  apply_rule('deny')
end

action :reject do
  apply_rule('reject')
end

private

$chain = { :in => "INPUT", :out => "OUTPUT", :pre => "PREROUTING", :post => "POSTROUTING"}#, nil => "FORWARD"}
$target = { "allow" => "ACCEPT", "reject" => "REJECT", "deny" => "DROP" }

def apply_rule(type=nil)
  if @new_resource.position
    firewall_command = "iptables -I #{@new_resource.position} "
  else
    firewall_command = "iptables -A "
  end
  
  firewall_rule = ""
  if @new_resource.direction
    firewall_rule << "#{$chain[@new_resource.direction]} "
  else
    firewall_rule << "FORWARD "
  end
  firewall_rule << "-s #{@new_resource.source} " if @new_resource.source
  firewall_rule << "-p #{@new_resource.protocol} " if @new_resource.protocol
  firewall_rule << "--dport #{@new_resource.dest_port} " if @new_resource.dest_port
  firewall_rule << "-i #{@new_resource.interface} " if @new_resource.interface
  firewall_rule << "-o #{@new_resource.dest_interface} " if @new_resource.dest_interface
  firewall_rule << "-d #{@new_resource.destination} " if @new_resource.destination
  firewall_rule << "-m state --state #{@new_resource.stateful} " if @new_resource.stateful
  firewall_rule << "-j #{$target[type]} "
  
  #TODO implement logging for :connections :packets
  
  Chef::Log.debug("#{@new_resource}: #{firewall_rule}")
  unless rule_exists?firewall_rule
    shell_out!(firewall_command+firewall_rule)
    Chef::Log.info("#{@new_resource} #{type} rule added into iptables")
    @new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug("#{@new_resource} #{type} rule exists..skipping.")
  end
end


def rule_exists? rule
  cmd = shell_out!("iptables -C #{rule}")
  true
rescue Mixlib::ShellOut::ShellCommandFailed
  Chef::Log.debug("#{@new_resource} check fails with:"+ cmd.inspect)
  Chef::Log.debug("#{@new_resource} assuming rule does not exist")
  false
end

