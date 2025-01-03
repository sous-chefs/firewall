#
# Cookbook:: firewall
# Recipe:: default
#
# Copyright:: 2011-2019, Chef Software, Inc.
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

# create a variable to use as a condition on some rules that follow
iptables_firewall = node['firewall']['solution'] == 'iptables'

firewall 'default' do
  ipv6_enabled node['firewall']['ipv6_enabled'] if iptables_firewall
  action :install
end

firewall_rule 'allow world to ssh' do
  port 22
  source '0.0.0.0/0'
  only_if { linux? && node['firewall']['allow_ssh'] }
end

firewall_rule 'allow world to winrm' do
  port 5989
  source '0.0.0.0/0'
  only_if { windows? && node['firewall']['allow_winrm'] }
end

firewall_rule 'allow world to mosh' do
  protocol :udp
  port 60000..61000
  source '0.0.0.0/0'
  only_if { linux? && node['firewall']['allow_mosh'] }
end

return unless iptables_firewall

# iptables only rules below

# TODO: These should probably just be removed. They are a bit deceiving because
# if one sets `node['firewall']['allow_icmp'] = false`, one would expect that to
# mean disable/remove the rule but really it means "ignore", which leaves the
# port open instead of closing it.

firewall_rule 'allow loopback' do
  interface 'lo'
  protocol :none
  command :allow
  # Modern firewalls allow loopback by default, limit to just iptables
  only_if { iptables_firewall && node['firewall']['allow_loopback'] }
end

firewall_rule 'allow icmp' do
  protocol :icmp
  command :allow
  # debian ufw doesn't allow 'icmp' protocol, but does open
  # icmp by default, so we skip it in default recipe
  only_if { iptables_firewall && node['firewall']['allow_icmp'] }
end

# allow established connections, ufw defaults to this but iptables does not
firewall_rule 'established' do
  stateful [:related, :established]
  protocol :none # explicitly don't specify protocol
  command :allow
  only_if { node['firewall']['allow_established'] && iptables_firewall }
end

# ipv6 needs ICMP to reliably work, so ensure it's enabled if ipv6
# allow established connections, ufw defaults to this but iptables does not
firewall_rule 'ipv6_icmp' do
  protocol :'ipv6-icmp'
  command :allow
  only_if { node['firewall']['ipv6_enabled'] && node['firewall']['allow_established'] && iptables_firewall }
end
