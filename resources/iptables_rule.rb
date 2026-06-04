# frozen_string_literal: true

unified_mode true

use '_partial/_firewall_rule'

provides :iptables_rule
default_action :create

property :direction, Symbol, equal_to: [:in, :out, :pre, :post], default: :in
property :logging, Symbol, equal_to: [:connections, :packets]
property :interface, String
property :dest_interface, String
property :stateful, [Symbol, Array]
property :include_comment, [true, false], default: true
property :program, String
property :service, String
property :raw, String
property :notify_firewall, [true, false], default: true

action :create do
  return unless new_resource.notify_firewall

  Chef.run_context.resource_collection.find(iptables: new_resource.firewall_name).delayed_action(:rebuild)
end
