# frozen_string_literal: true

unified_mode true

# Common properties defined in a resource partial
use '_partial/_firewall_rule'

provides :firewall_rule
default_action :create

property :zone, String

property :direction, Symbol, equal_to: [:in, :out, :pre, :post], default: :in
property :logging, Symbol, equal_to: [:connections, :packets]
property :interface, String
property :dest_interface, String
property :stateful, [Symbol, Array]
property :include_comment, [true, false], default: true

# only used for Windows Firewalls
property :program, String
property :service, String

# for when you just want to pass a raw rule
property :raw, String

# do you want this rule to notify the firewall to recalculate
# (and potentially reapply) the firewall_rule(s) it finds?
property :notify_firewall, [true, false], default: true

%i(create delete).each do |operation|
  action operation do
    rule = new_resource
    parent = Chef.run_context.resource_collection.find(firewall: rule.firewall_name)
    if parent.backend == :firewalld
      unsupported = %i(direction logging interface dest_interface stateful include_comment program service raw).select do |property|
        rule.property_is_set?(property)
      end
      raise ArgumentError, "Unsupported firewalld rule properties: #{unsupported.join(', ')}" unless unsupported.empty?
      firewall_rule_firewalld rule.name do
        %i(command protocol source source_port port dest_port destination position description redirect_port zone).each do |property|
          public_send(property, rule.public_send(property)) if rule.property_is_set?(property)
        end
        action operation
      end
    else
      with_run_context :root do
        edit_resource!(:firewall, rule.firewall_name) do
          rule_resources(rule_resources + [rule]) if operation == :create
          delayed_action :restart if rule.notify_firewall
        end
      end
    end
  end
end
