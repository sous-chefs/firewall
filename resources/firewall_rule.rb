
unified_mode true

# Common properties defined in a resource partial
use '_partial/_firewall_rule'

# non-firewalld platforms only
provides :firewall_rule do
  !platform_family?('rhel', 'fedora', 'amazon')
end

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

action :create do
  return unless new_resource.notify_firewall

  firewall_resource = Chef.run_context.resource_collection.find(firewall: new_resource.firewall_name)
  raise 'could not find a firewall resource' unless firewall_resource

  new_resource.notifies(:restart, firewall_resource, :delayed)
  new_resource.updated_by_last_action(true)
end
