#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook Name:: firewall
# Resource:: default
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
class Chef
  class Provider::FirewallFirewalld < Provider
    include Poise
    include Chef::Mixin::ShellOut

    def action_enable
      # prints all the firewall rules
      # pp @new_resource.subresources
      log_current_firewalld
      if active?
        Chef::Log.debug("#{@new_resource} already enabled.")
      else
        Chef::Log.debug("#{@new_resource} is about to be enabled")
        shell_out!("echo firewall-cmd --set-default-zone=drop")
        Chef::Log.info("#{@new_resource} enabled.")
        new_resource.updated_by_last_action(true)
      end
    end

    def action_disable
      if active?
        shell_out!("echo firewall-cmd --set-default-zone=public")
        shell_out!("echo firewall-cmd --remove-rules ipv4 filter INPUT")
        shell_out!("echo firewall-cmd --remove-rules ipv4 filter OUTPUT")
        Chef::Log.info("#{@new_resource} disabled")
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.debug("#{@new_resource} already disabled.")
      end
    end

    def action_flush
      shell_out!("echo firewall-cmd --remove-rules ipv4 filter INPUT")
      shell_out!("echo firewall-cmd --remove-rules ipv4 filter OUTPUT")
      Chef::Log.info("#{@new_resource} flushed.")
    end

    private

    def active?
      @active ||= begin
        cmd = shell_out!('firewall-cmd --state')
        cmd.stdout =~ /^running$/
      end
    end

    def log_current_firewalld
      cmdstr = 'firewall-cmd --direct --get-all-rules'
      Chef::Log.info("#{@new_resource} log_current_firewalld (#{cmdstr}):")
      cmd = shell_out!(cmdstr)
      Chef::Log.info(cmd.inspect)
    rescue
      Chef::Log.info("#{@new_resource} log_current_firewalld failed!")
    end
  end
end
