
require 'ipaddr'

unified_mode true

provides :firewall_rule

default_action :create

property :firewall_name, String, default: 'default'
property :command, Symbol, equal_to: [:reject, :allow, :deny, :masquerade, :redirect, :log], default: :allow
property :protocol, [Integer, Symbol], default: :tcp,
         callbacks: {
          'must be either :tcp, :udp, :icmp, :\'ipv6-icmp\', :icmpv6, :none, or a valid IP protocol number' =>
            lambda do |p|
              !!(p.to_s =~ /(udp|tcp|icmp|icmpv6|ipv6-icmp|esp|ah|ipv6|none)/ || (p.to_s =~ /^\d+$/ && p.between?(0, 142)))
            end }

property :direction, Symbol, equal_to: [:in, :out, :pre, :post], default: :in
property :logging, Symbol, equal_to: [:connections, :packets]
property :source, String, callbacks: { 'must be a valid ip address' => ->(ip) { !!IPAddr.new(ip) } }
property :source_port, [Integer, Array, Range]
property :interface, String
property :port, [Integer, Array, Range]
property :destination, String, callbacks: { 'must be a valid ip address' => ->(ip) { !!IPAddr.new(ip) } }
property :dest_port, [Integer, Array, Range]
property :dest_interface, String
property :position, Integer, default: 50
property :stateful, [Symbol, Array]
property :redirect_port, Integer
property :description, String, name_property: true
property :include_comment, [true, false], default: true

# only used for firewalld
property :permanent, [true, false], default: false

property :zone, String

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
