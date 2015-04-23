class Chef
  class Resource::FirewallRule < Resource
    include Poise(Chef::Resource::Firewall)

    # Match ipv4 or ipv6 address, with optional /cidr notation
    IP_CIDR_VALID_REGEX = /(^\s*((([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])(\/([0-9]|[1-2][0-9]|3[0-2]))?)\s*$)|(^\s*(s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]d|1dd|[1-9]?d)(.(25[0-5]|2[0-4]d|1dd|[1-9]?d)){3}))|:)))(%.+)?s*(\/(d|dd|1[0-1]d|12[0-8]))?)(%.+)?\s*$)/

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
