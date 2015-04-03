class Chef
  class Resource::FirewallRule < Resource
    include Poise(Chef::Resource::Firewall)

    IP_CIDR_VALID_REGEX = /\b(?:\d{1,3}\.){3}\d{1,3}\b(\/[0-3]?[0-9])?/

    actions(:reject, :allow, :deny, :masquerade, :redirect, :log, :remove)

    attribute(:protocol, :kind_of => [Symbol, String], :equal_to => [:udp, :tcp, :icmp, 'tcp', 'udp', 'icmp'], :default => :tcp)
    attribute(:direction, :kind_of => [Symbol, String], :equal_to => [:in, :out, :pre, :post, 'in', 'out', 'pre', 'post'], :default => :in)
    attribute(:logging, :kind_of => [Symbol, String], :equal_to => [:connections, :packets, 'connections', 'packets'])

    attribute(:source, :regex => IP_CIDR_VALID_REGEX)
    attribute(:source_port, :kind_of => [Integer, Array, Range]) # source port
    attribute(:interface, :kind_of => String)

    attribute(:port, :kind_of => [Integer, Array, Range]) # shorthand for dest_port
    attribute(:destination, :regex => IP_CIDR_VALID_REGEX)
    attribute(:dest_port, :kind_of => [Integer, Array, Range])
    attribute(:dest_interface, :kind_of => String)

    attribute(:position, :kind_of => Integer)
    attribute(:stateful, :kind_of => [Symbol, String, Array])
    attribute(:redirect_port, :kind_of => Integer)
    attribute(:description, :kind_of => String, :name_attribute => true)

    # for when you just want to pass a raw rule
    attribute(:raw, :kind_of => String)
  end
end
