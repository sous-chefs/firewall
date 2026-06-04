# frozen_string_literal: true

unified_mode true

use '_partial/_firewall_rule'

provides :windows_firewall_rule
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

action :create do
  firewall_resource = Chef.run_context.resource_collection.find(firewall: new_resource.firewall_name)
  raise 'could not find a firewall resource' unless firewall_resource

  with_run_context :root do
    edit_resource!(:firewall, new_resource.firewall_name) do
      delayed_action :restart
    end
  end
end
