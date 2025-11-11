
require 'ipaddr'

unified_mode true

default_action :create

property :firewall_name, String, default: 'default'
property :command, Symbol, equal_to: [:reject, :allow, :deny, :masquerade, :redirect, :log], default: :allow
property :protocol, [Integer, Symbol], default: :tcp,
                                       callbacks: {
                                         'must be either :tcp, :udp, :icmp, :\'ipv6-icmp\', :icmpv6, :none, or a valid IP protocol number' =>
                                           lambda do |p|
                                             !!(p.to_s =~ /(udp|tcp|icmp|icmpv6|ipv6-icmp|esp|ah|ipv6|none)/ || (p.to_s =~ /^\d+$/ && p.between?(0, 142)))
                                           end }

property :source, String, callbacks: { 'must be a valid ip address' => ->(ip) { !!IPAddr.new(ip) } }
property :source_port, [Integer, Array, Range]
property :port, [Integer, Array, Range] # shorthand for :dest_port
property :dest_port, [Integer, Array, Range]
property :destination, String, callbacks: { 'must be a valid ip address' => ->(ip) { !!IPAddr.new(ip) } }
property :position, Integer, default: 50
property :description, String, name_property: true
property :redirect_port, Integer
