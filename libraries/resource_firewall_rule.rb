class Chef
  class Resource::FirewallRule < Resource
    include Poise(Chef::Resource::Firewall)
    provides :firewall_rule

    IP_CIDR_VALID_REGEX = /\b(?:\d{1,3}\.){3}\d{1,3}\b(\/[0-3]?[0-9])?/

    actions(:reject, :allow, :deny)

    attribute(:port, :kind_of => [Integer, Array, Range])
    attribute(:protocol, :kind_of => [Symbol, String], :equal_to => [:udp, :tcp, 'tcp', 'udp'])
    attribute(:direction, :kind_of => [Symbol, String], :equal_to => [:in, :out, 'in', 'out'])
    attribute(:interface, :kind_of => String)
    attribute(:logging, :kind_of => [Symbol, String], :equal_to => [:connections, :packets, 'connections', 'packets'])
    attribute(:source, :regex => IP_CIDR_VALID_REGEX)
    attribute(:destination, :regex => IP_CIDR_VALID_REGEX)
    attribute(:dest_port, :kind_of => Integer)
    attribute(:position, :kind_of => Integer)

  end
end
