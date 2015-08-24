#
# Author:: Sander van Harmelen (<svanharmelen@schubergphilis.com>)
# Cookbook Name:: firewall
# Provider:: windows
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
  class Provider::FirewallWindows < Provider
    include Poise
    include Chef::Mixin::ShellOut

    def action_enable
      converge_by('enable and start Windows Firewall service') do

        service 'MpsSvc' do
          action [:enable, :start]
        end

        if active?
          Chef::Log.debug("#{new_resource} already enabled.")
        else
          shell_out!('netsh advfirewall set currentprofile state on')
          Chef::Log.info("#{new_resource} enabled.")
          new_resource.updated_by_last_action(true)
        end
      end
    end

    def action_disable
      if active?
        shell_out!('netsh advfirewall set currentprofile state off')
        Chef::Log.info("#{new_resource} disabled.")
        new_resource.updated_by_last_action(true)
      else
        Chef::Log.debug("#{new_resource} already disabled.")
      end

      service 'MpsSvc' do
        action [:disable, :stop]
      end
    end

    def action_reset
      shell_out!('netsh advfirewall reset')
      Chef::Log.info("#{new_resource} reset.")
    end

    private

    def active?
      @active ||= begin
        cmd = shell_out!('netsh advfirewall show currentprofile')
        cmd.stdout =~ /^State\sON/
      end
    end
  end
end
