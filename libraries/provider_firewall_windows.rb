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

class Chef
  class Provider::FirewallWindows < Chef::Provider::LWRPBase
    include FirewallCookbook::Helpers::Windows

    provides :firewall, os: 'windows'

    def whyrun_supported?
      false
    end

    action :install do
      next if disabled?(new_resource)

      converge_by('enable and start Windows Firewall service') do
        service 'MpsSvc' do
          action [:enable, :start]
        end
      end
    end

    action :restart do
      next if disabled?(new_resource)

      # ensure it's initialized
      new_resource.rules({}) unless new_resource.rules
      new_resource.rules['windows'] = {} unless new_resource.rules['windows']

      firewall_rules = run_context.resource_collection.select { |item| item.is_a?(Chef::Resource::FirewallRule) }
      firewall_rules.each do |firewall_rule|
        next unless firewall_rule.action.include?(:create) && !firewall_rule.should_skip?(:create)

        # build rules to apply with weight
        k = build_rule(firewall_rule)
        v = firewall_rule.position

        # unless we're adding them for the first time.... bail out.
        unless new_resource.rules['windows'].key?(k) && new_resource.rules['windows'][k] == v
          new_resource.rules['windows'][k] = v
        end
      end

      # ensure a file resource exists with the current rules
      begin
        windows_file = run_context.resource_collection.find(file: windows_rules_filename)
      rescue
        windows_file = file windows_rules_filename do
          action :nothing
        end
      end
      windows_file.content build_rule_file(new_resource.rules['windows'])
      windows_file.run_action(:create)

      # if the file was changed
      # OR
      # if current_rule_count is not equal to the number of rules in file
      #   which can mean: no additional rules added but default rule set was
      #   installed before and now it is desired not to install them
      #   OR
      #   which can mean: no additional rules added but rules changed externally
      # OR
      # if current_rule_count is equal to the number of rules in file AND
      # windows_default_rules is true
      #   which means no additional rules added but default rule set was NOT
      #   installed before and now it is desired to install them
      #
      # So in these conditions shake and bake firewall service and rules
      if windows_file.updated_by_last_action? ||
         new_resource.rules['windows'].length != current_rule_count! ||
         (new_resource.rules['windows'].length == current_rule_count! &&
          new_resource.windows_default_rules)
        disable! if active?
        delete_all_rules! # clear entirely

        # If it is required to apply default windows rules, execute reset! to install them
        reset! if new_resource.windows_default_rules # populate default rules

        new_resource.rules['windows'].sort_by { |_k, v| v }.map { |k, _v| k }.each do |cmd|
          add_rule!(cmd)
        end
        # ensure it's enabled _after_ rules are inputted, to catch malformed rules
        enable! unless active?

        new_resource.updated_by_last_action(true)
      end
    end

    action :disable do
      next if disabled?(new_resource)

      converge_by('disable and stop Windows Firewall service') do
        if active?
          disable!
          Chef::Log.info("#{new_resource} disabled.")
          new_resource.updated_by_last_action(true)
        else
          Chef::Log.debug("#{new_resource} already disabled.")
        end

        service 'MpsSvc' do
          action [:disable, :stop]
        end
      end
    end

    action :flush do
      next if disabled?(new_resource)

      reset!
      Chef::Log.info("#{new_resource} reset.")
    end
  end
end
