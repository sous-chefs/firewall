#
# Author:: Ronald Doorn (<rdoorn@schubergphilis.com)
# Cookbook Name:: firewall
# Resource:: zone
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

actions :set

attribute :zone, :kind_of => String, :name_attribute => true
attribute :target, :kind_of => Symbol

def initialize(name, run_context = nil)
  super
  set_platform_default_providers
  @action = :set
end

private

def set_platform_default_providers
  [:redhat, :centos].each do |platform|
    if node['platform_version'][0] >= "7"
      Chef::Platform.set(
          :platform => platform,
          :resource => :firewall_zone,
          :provider => Chef::Provider::FirewallZoneFirewalld
      )
    else
      Chef::Platform.set(
          :platform => platform,
          :resource => :firewall_zone,
          :provider => Chef::Provider::FirewallZoneIptables
      )
    end
  end
end
