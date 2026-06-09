# frozen_string_literal: true

unified_mode true

use '_partial/_firewall_rule'
use '_partial/_backend_rule'

provides :windows_firewall_rule
default_action :create

action :create do
  return unless new_resource.notify_firewall

  Chef.run_context.resource_collection.find(windows_firewall: new_resource.firewall_name).delayed_action(:rebuild)
end
