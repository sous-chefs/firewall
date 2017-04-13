#
# Author:: Seth Chisamore (<schisamo@opscode.com>)
# Cookbook:: firewall
# Resource:: default
#
# Copyright:: 2011-2016, Chef Software, Inc.
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
  class Provider::FirewallIptables < Chef::Provider::LWRPBase
    include FirewallCookbook::Helpers
    include FirewallCookbook::Helpers::Iptables

    provides :firewall, os: 'linux', platform_family: %w(rhel fedora) do |node|
      node['platform_version'].to_f < 7.0 || node['firewall']['redhat7_iptables']
    end

    def whyrun_supported?
      false
    end

    def action_install
      return if disabled?(new_resource)

      # Ensure the package is installed
      iptables_packages(new_resource).each do |p|
        iptables_pkg = package p do
          action :nothing
        end
        iptables_pkg.run_action(:install)
        new_resource.updated_by_last_action(true) if iptables_pkg.updated_by_last_action?
      end

      iptables_commands(new_resource).each do |svc|
        # must create empty file for service to start
        unless ::File.exist?("/etc/sysconfig/#{svc}")
          # must create empty file for service to start
          iptables_file = lookup_or_create_rulesfile(svc)
          iptables_file.content '# created by chef to allow service to start'
          iptables_file.run_action(:create)
          new_resource.updated_by_last_action(true) if iptables_file.updated_by_last_action?
        end

        iptables_service = lookup_or_create_service(svc)
        [:enable, :start].each do |a|
          iptables_service.run_action(a)
          new_resource.updated_by_last_action(true) if iptables_service.updated_by_last_action?
        end
      end
    end

    def action_restart
      return if disabled?(new_resource)

      # prints all the firewall rules
      log_iptables(new_resource)

      # ensure it's initialized
      new_resource.rules({}) unless new_resource.rules
      ensure_default_rules_exist(node, new_resource)

      # this populates the hash of rules from firewall_rule resources
      firewall_rules = Chef.run_context.resource_collection.select { |item| item.is_a?(Chef::Resource::FirewallRule) }
      firewall_rules.each do |firewall_rule|
        next unless firewall_rule.action.include?(:create) && !firewall_rule.should_skip?(:create)

        types = if ipv6_rule?(firewall_rule) # an ip4 specific rule
                  %w(ip6tables)
                elsif ipv4_rule?(firewall_rule) # an ip6 specific rule
                  %w(iptables)
                else # or not specific
                  %w(iptables ip6tables)
                end

        types.each do |iptables_type|
          # build rules to apply with weight
          k = build_firewall_rule(node, firewall_rule, iptables_type == 'ip6tables')
          v = firewall_rule.position

          # unless we're adding them for the first time.... bail out.
          next if new_resource.rules[iptables_type].key?(k) && new_resource.rules[iptables_type][k] == v
          new_resource.rules[iptables_type][k] = v
        end
      end

      iptables_commands(new_resource).each do |iptables_type|
        # this takes the commands in each hash entry and builds a rule file
        iptables_file = lookup_or_create_rulesfile(iptables_type)
        iptables_file.content build_rule_file(new_resource.rules[iptables_type])
        iptables_file.run_action(:create)

        # if the file was unchanged, skip loop iteration, otherwise restart iptables
        next unless iptables_file.updated_by_last_action?

        iptables_service = lookup_or_create_service(iptables_type)
        new_resource.notifies(:restart, iptables_service, :delayed)
        new_resource.updated_by_last_action(true)
      end
    end

    def action_disable
      return if disabled?(new_resource)

      iptables_flush!(new_resource)
      iptables_default_allow!(new_resource)
      new_resource.updated_by_last_action(true)

      iptables_commands(new_resource).each do |svc|
        iptables_service = lookup_or_create_service(svc)
        [:disable, :stop].each do |a|
          iptables_service.run_action(a)
          new_resource.updated_by_last_action(true) if iptables_service.updated_by_last_action?
        end

        # must create empty file for service to start
        iptables_file = lookup_or_create_rulesfile(svc)
        iptables_file.content '# created by chef to allow service to start'
        iptables_file.run_action(:create)
        new_resource.updated_by_last_action(true) if iptables_file.updated_by_last_action?
      end
    end

    def action_flush
      return if disabled?(new_resource)

      iptables_flush!(new_resource)
      new_resource.updated_by_last_action(true)

      iptables_commands(new_resource).each do |svc|
        # must create empty file for service to start
        iptables_file = lookup_or_create_rulesfile(svc)
        iptables_file.content '# created by chef to allow service to start'
        iptables_file.run_action(:create)
        new_resource.updated_by_last_action(true) if iptables_file.updated_by_last_action?
      end
    end

    def lookup_or_create_service(name)
      begin
        iptables_service = Chef.run_context.resource_collection.find(service: svc)
      rescue
        iptables_service = service name do
          action :nothing
        end
      end
      iptables_service
    end

    def lookup_or_create_rulesfile(name)
      begin
        iptables_file = Chef.run_context.resource_collection.find(file: name)
      rescue
        iptables_file = file "/etc/sysconfig/#{name}" do
          action :nothing
        end
      end
      iptables_file
    end
  end
end
