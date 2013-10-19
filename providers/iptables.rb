#
# Cookbook Name:: firewall
# Provider:: iptables
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


action :enable do
  shell_out!("iptables -P INPUT DROP")
  shell_out!("iptables -P OUTPUT DROP")
  shell_out!("iptables -P FORWARD DROP")
  Chef::Log.debug("#{@new_resource} enabled.")
  new_resource.updated_by_last_action(false)
end

action :disable do
  shell_out!("iptables -P INPUT ACCEPT")
  shell_out!("iptables -P OUTPUT ACCEPT")
  shell_out!("iptables -P FORWARD ACCEPT")
  shell_out!("iptables -F")
  Chef::Log.debug("#{@new_resource} disabled.")
  new_resource.updated_by_last_action(false)
end

action :flush do
  shell_out!("iptables -F")
  Chef::Log.debug("#{@new_resource} flushed.")
  new_resource.updated_by_last_action(false)
end
