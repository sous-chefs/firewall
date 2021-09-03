#
# Author:: Matthias Pausch (<>)
# Cookbook:: firewall
# Resource:: default
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
class Chef
  class Provider
    class FirewallNftables < Chef::Provider::LWRPBase
      include FirewallCookbook::Helpers
      include FirewallCookbook::Helpers::Nftables

      provides :firewall, os: 'linux', platform: %w(debian) do |node|
        node['firewall'] && node['firewall']['debian_nftables'] &&
          node['platform_version'].to_f >= (node['platform'] == 'ubuntu' ? 20.10 : 10)
      end

      def whyrun_supported?
        false
      end

      action :install do
        return if disabled?(new_resource)

        # Ensure the package is installed
        nftables_packages.each do |p|
          nftables_pkg = package p do
            action :nothing
          end
          nftables_pkg.run_action(:install)
          new_resource.updated_by_last_action(true) if nftables_pkg.updated_by_last_action?
        end

        # must create empty file for service to start
        unless ::File.exist?('/etc/nftables.conf')
          # must create empty file for service to start
          nftables_file = lookup_or_create_rulesfile('/etc/nftables.conf')
          nftables_file.content '# created by chef to allow service to start'
          nftables_file.run_action(:create)
          new_resource.updated_by_last_action(true) if nftables_file.updated_by_last_action?
        end

        nftables_service = lookup_or_create_service('nftables')
        %i(enable start).each do |a|
          nftables_service.run_action(a)
          new_resource.updated_by_last_action(true) if nftables_service.updated_by_last_action?
        end
      end

      action :restart do
        return if disabled?(new_resource)

        # prints all the firewall rules
        log_nftables

        # ensure it's initialized
        new_resource.rules({}) unless new_resource.rules
        ensure_default_rules_exist(node, new_resource)

        # this populates the hash of rules from firewall_rule resources
        firewall_rules = Chef.run_context.resource_collection.select { |item| item.is_a?(Chef::Resource::FirewallRule) }
        firewall_rules.each do |firewall_rule|
          next unless firewall_rule.action.include?(:create) && !firewall_rule.should_skip?(:create)

          # build rules to apply with weight
          k = build_firewall_rule(firewall_rule)
          v = firewall_rule.position

          # unless we're adding them for the first time.... bail out.
          next if new_resource.rules.key?(k) && new_resource.rules[k] == v

          new_resource.rules[k] = v
        end

        # this takes the commands in each hash entry and builds a rule file
        nftables_file = lookup_or_create_rulesfile('/etc/nftables.conf')
        nftables_file.content "#!/usr/sbin/nft -f\nflush ruleset\n#{build_rule_file(new_resource.rules)}"
        nftables_file.run_action(:create)

        # if the file was unchanged, skip loop iteration, otherwise restart nftables
        return unless nftables_file.updated_by_last_action?

        nftables_service = lookup_or_create_service('nftables')
        nftables_service.run_action(:restart)
        new_resource.updated_by_last_action(true)
      end

      action :disable do
        return if disabled?(new_resource)

        nftables_flush!
        nftables_default_allow!
        new_resource.updated_by_last_action(true)

        nftables_service = lookup_or_create_service('nftables')
        %i(disable stop).each do |a|
          nftables_service.run_action(a)
          new_resource.updated_by_last_action(true) if nftables_service.updated_by_last_action?
        end

        # must create empty file for service to start
        nftables_file = lookup_or_create_rulesfile
        nftables_file.content "#!/usr/sbin/nft -f\n# created by chef to allow service to start"
        nftables_file.run_action(:create)
        new_resource.updated_by_last_action(true) if nftables_file.updated_by_last_action?
      end

      action :flush do
        return if disabled?(new_resource)

        nftables_flush!
        new_resource.updated_by_last_action(true)

        # must create empty file for service to start
        nftables_file = lookup_or_create_rulesfile('/etc/nftables.conf')
        nftables_file.content "#!/usr/sbin/nft -f\n# created by chef to allow service to start"
        nftables_file.run_action(:create)
        new_resource.updated_by_last_action(true) if nftables_file.updated_by_last_action?
      end

      def lookup_or_create_service(name)
        begin
          nftables_service = Chef.run_context.resource_collection.find(service: name)
        rescue
          nftables_service = service name do
            action :nothing
          end
        end
        nftables_service
      end

      def lookup_or_create_rulesfile(name)
        begin
          nftables_file = Chef.run_context.resource_collection.find(file: name)
        rescue
          nftables_file = file name do
            action :nothing
          end
        end
        nftables_file
      end
    end
  end
end
