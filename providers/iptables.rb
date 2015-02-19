#
# Author:: Ronald Doorn (<rdoorn@schubergphilis.com>)
# Cookbook Name:: firwall
# Provider:: iptables
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
  if active?
    Chef::Log.debug("#{@new_resource} already enabled.")
  else
    shell_out!('service iptables start')
    Chef::Log.info("#{@new_resource} started")
    shell_out!('chkconfig iptables on')
    Chef::Log.info("#{@new_resource} enabled")
    new_resource.updated_by_last_action(true)
  end
end

action :disable do
  if active?
    shell_out!('service iptables stop')
    Chef::Log.info("#{@new_resource} disabled")
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug("#{@new_resource} already disabled.")
  end
end

action :save do
  if active?
    shell_out!('service iptables save')
    Chef::Log.info("#{@new_resource} saved")
    new_resource.updated_by_last_action(true)
  else
    Chef::Log.debug("#{@new_resource} currently disabled. - not saving")
  end
end

private

def active?
  @active ||= begin
    cmd = shell_out('service iptables status')
    Chef::Log.debug("#{@new_resource} status returns #{cmd.exitstatus}")
    cmd.exitstatus == 0
  end
end
