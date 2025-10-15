
require 'ipaddr'

unified_mode true

provides :firewalld_rich_rule, os: 'linux'

default_action :add

property :family,
         Symbol,
         equal_to: [:ipv4, :ipv6],
         description: 'IP family for the rule, either IPv4 or IPv6. If the family is not provided, the rule will be added for both IPv4 and IPv6. If source or destination addresses are used in the rule, then the rule family defaults to the type of address given in source and/or destination. This is also the case for port/packet forwarding. See rule "family" option in firewalld.richlanguage(5).'

property :zone,
         String,
         description: "Zone in which to apply the rule. If not specified, the rule will be applied to the systems's default zone."

property :priority,
         Integer,
         description: 'Specifies the priority of the rule, ranging from -32768 to 32767. Lower values have higher precedence. See rule option "priority" in firewalld.richlanguage(5).'

property :source,
         String,
         callbacks: { 'must be a valid IP address or network range in CIDR notation' => ->(ip) { !!IPAddr.new(ip) } },
         description: 'Source address or network range in CIDR notation to match for the rule. See "Source" in firewalld.richlanguage(5).'

property :source_not,
         String,
         callbacks: { 'must be a valid IP address or network range in CIDR notation' => ->(ip) { !!IPAddr.new(ip) } },
         description: 'Excludes a specific source address or network range in CIDR notation from matching the rule. See "Source" in firewalld.richlanguage(5).'

property :destination,
         String,
         callbacks: { 'must be a valid IP address or network range in CIDR notation' => ->(ip) { !!IPAddr.new(ip) } },
         description: 'Destination address or network range in CIDR notation to match for the rule. See "Destination" in firewalld.richlanguage(5).'

property :destination_not,
         String,
         callbacks: { 'must be a valid IP address or range in CIDR notation' => ->(ip) { !!IPAddr.new(ip) } },
         description: 'Excludes a specific destination address or network range in CIDR notation from matching the rule. See "Destination" in firewalld.richlanguage(5).'

property :service,
         String,
         description: "Service to apply the rule to, using firewalld's predefined service names. See \"Service\" in firewalld.richlanguage(5)."

property :port,
         [Integer, String],
         description: 'Single port or a range of ports to match for the rule. Requires the `protocol` property to also be specified. See "Port" in firewalld.richlanguage(5).'

property :protocol,
         String,
         description: 'Defines the protocol by name or ID (e.g. tcp, udp, icmp). See "Protocol" in firewalld.richlanguage(5).'

property :tcp_mss_clamp,
         [String, Integer],
         description: 'Sets the maximum segment size (MSS) for TCP connections. See "Tcp-Mss-Clamp" in firewalld.richlanguage(5).'

property :icmp_block,
         String,
         description: 'Blocks specific ICMP types (e.g. "echo-request") as defined by firewalld. A `rule_action` is not allowed with this property, "reject" is used implicitly. See "ICMP-Block" in firewalld.richlanguage(5).'

property :masquerade,
         [true, false],
         default: false,
         description: 'Enables masquerading (NAT) for the rule. A `rule_action` is not allowed with this property, IP forwarding will be implicitly enabled. See "Masquerade" in firewalld.richlanguage(5).'

property :icmp_type,
         String,
         description: 'Specifies the ICMP type to match (e.g. "echo-request"). See "ICMP-Type" in firewalld.richlanguage(5).'

property :forward_port,
         [Integer, String],
         description: 'Forward a local port or a range of local ports to another port locally or to another machine. Requires the `protocol` property and one or both of `to_port`/`to_address` properties. A `rule_action` is not allowed with this property, uses the action "accept" internally. See "Forward-Port" in firewalld.richlanguage(5).'

property :to_port,
         Integer,
         description: 'The port to forward traffic to. See "Forward-Port" in firewalld.richlanguage(5).'

property :to_address,
         String,
         callbacks: { 'must be a valid IP address' => ->(ip) { !!IPAddr.new(ip) } },
         description: 'The IP address to forward traffic to. See "Forward-Port" in firewalld.richlanguage(5).'

property :source_port,
         [Integer, String],
         description: 'The source port or range of source ports to match for the rule. Requires the `protocol` property to also be specified. See "Source-Port" in firewalld.richlanguage(5).'

property :log,
         [true, false],
         default: false,
         description: 'Enables logging for the rule. See "Log" in firewalld.richlanguage(5).'

property :log_prefix,
         String,
         description: 'Adds a prefix to log messages for identification. Maximum length is 127 characters. See "Log" in firewalld.richlanguage(5).'

property :log_level,
         Symbol,
         equal_to: [:emerg, :alert, :crit, :error, :warning, :notice, :info, :debug],
         default: :warning,
         description: 'Log level can be one of `:emerg`, `:alert`, `:crit`, `:error`, `:warning`, `:notice`, `:info`, `:debug`. Default is `:warning`. See "Log" in firewalld.richlanguage(5).'

property :log_limit,
         String,
         description: 'Limits the rate of log messages in the format "rate/duration" (e.g., `5/s`). See "Limit" in firewalld.richlanguage(5).'

property :nflog,
         [true, false],
         default: false,
         description: 'Log new connection attempts using kernel logging to pass the packets through a "netlink" socket to users or applications monitoring the multicast "group". See "NFLog" in firewalld.richlanguage(5).'

property :nflog_group,
         Integer,
         description: 'The NFLOG group ID for the rule (0-65535). See NETLINK_NETFILTER in netlink(7) man page and NFLOG in both iptables-extensions(8) and nft(8) man pages for a more detailed description.'

property :nflog_prefix,
         String,
         description: 'Adds a prefix to NFLog messages for identification. Maximum length is 127 characters. See "NFLog" in firewalld.richlanguage(5).'

property :nflog_queue_size,
         Integer,
         description: 'Sets the queue size for NFLog messages. See "NFLog" in firewalld.richlanguage(5).'

property :nflog_limit,
         String,
         description: 'Limits the rate of NFLog messages in the format "rate/duration" (e.g. `10/m`). See "Limit" in firewalld.richlanguage(5).'

property :audit,
         [true, false],
         default: false,
         description: 'Audit provides an alternative way for logging using audit records sent to the service auditd. Audit type will be discovered from the rule action automatically. See "Audit" in firewalld.richlanguage(5).'

property :audit_limit,
         String,
         description: 'Limits the rate of audit messages in the format "rate/duration" (e.g. `1/s`). See "Limit" in firewalld.richlanguage(5).'

property :rule_action,
         Symbol,
         equal_to: [:accept, :reject, :drop, :mark],
         description: 'The action for the rule. One of `:accept`, `:reject`, `:drop`, `:mark`. See "Action" in firewalld.richlanguage(5).'

property :reject_type,
         String,
         description: 'Optional reject type to use with the `:reject` rule_action. See "Action" in firewalld.richlanguage(5).'

property :mark_set,
         String,
         description: 'The mark value to set for matched packets (e.g. "0x1"). See "Action" in firewalld.richlanguage(5).'

property :action_limit,
         String,
         description: 'Specifies a general rate limit for the rule in the format "rate/duration" (e.g. `20/s`). See "Limit" in firewalld.richlanguage(5).'

property :raw,
         String,
         description: "A raw rule string (e.g. \"rule ...\") passed directly to firewalld, bypassing this resource's internal validation and handling. All other properties are ignored. See \"Rule\" in firewalld.richlanguage(5)."

action :add do
  rule = get_rich_rule_string

  begin
    sysbus = DBus.system_bus
    zone_config = get_zone_config(sysbus)
    rule_exists = zone_config.queryRichRule(rule)

    unless rule_exists
      converge_by rule do
        zone_config.addRichRule(rule)
        firewalld_interface(sysbus).reload
      end
    end
  rescue DBus::Error => e
    raise "Failed to add firewalld rich rule \"#{rule}\": #{e.message}"
  end
end

action :remove do
  rule = get_rich_rule_string

  begin
    sysbus = DBus.system_bus
    zone_config = get_zone_config(sysbus)
    rule_exists = zone_config.queryRichRule(rule)

    if rule_exists
      converge_by rule do
        zone_config.removeRichRule(rule)
        firewalld_interface(sysbus).reload
      end
    end
  rescue DBus::Error => e
    raise "Failed to remove firewalld rich rule \"#{rule}\": #{e.message}"
  end
end

action_class do
  include FirewallCookbook::Helpers::FirewalldDBus

  def get_rich_rule_string
    if (property_is_set?(:port) || property_is_set?(:forward_port) || property_is_set?(:source_port)) &&
       !property_is_set?(:protocol)
      raise 'Property "protocol" is required when using "port", "forward_port", or "source_port" properties.'
    end

    if new_resource.rule_action == :mark && !property_is_set?(:mark_set)
      raise 'Property "mark_set" is required when using the "mark" rule_action.'
    end

    # :raw takes precedence if specified, ignoring all other properties.
    # Otherwise, build the rich rule string based on given properties
    rule = property_is_set?(:raw) ? new_resource.raw : build_rich_rule
    Chef::Log.debug rule
    rule
  end

  def get_zone_config(sysbus)
    firewalld_service = sysbus['org.fedoraproject.FirewallD1']
    firewalld_object = firewalld_service['/org/fedoraproject/FirewallD1/config']
    fw_config = firewalld_object['org.fedoraproject.FirewallD1.config']

    zone_name = property_is_set?(:zone) ? new_resource.zone : get_default_zone(sysbus)
    zone_path = fw_config.getZoneByName(zone_name)
    zone_object = firewalld_service[zone_path]
    zone_object['org.fedoraproject.FirewallD1.config.zone']
  end

  def requires_family?
    property_is_set?(:family) || property_is_set?(:forward_port) ||
      property_is_set?(:source) || property_is_set?(:source_not) ||
      property_is_set?(:destination) || property_is_set?(:destination_not) ||
      property_is_set?(:to_address)
  end

  def ip_family
    # If they explicitly set family then leave as-is
    return new_resource.family if property_is_set?(:family)

    return unless requires_family?

    # Determine the IP address family based on provided properties
    [:source, :source_not, :destination, :destination_not, :to_address].each do |property|
      next unless new_resource.property_is_set?(property)
      ip = IPAddr.new(new_resource.send(property))
      return ip.ipv4? ? :ipv4 : :ipv6
    end

    nil
  end

  # A helper method within action_class to construct the rich rule string
  def build_rich_rule
    r = new_resource

    rule_parts = []
    rule_parts << 'rule'
    rule_parts << "family=\"#{ip_family}\"" if ip_family
    rule_parts << "priority=\"#{r.priority}\""                         if property_is_set?(:priority)
    rule_parts << "source address=\"#{r.source}\""                     if property_is_set?(:source)
    rule_parts << "source not address=\"#{r.source_not}\""             if property_is_set?(:source_not)
    rule_parts << "destination address=\"#{r.destination}\""           if property_is_set?(:destination)
    rule_parts << "destination not address=\"#{r.destination_not}\""   if property_is_set?(:destination_not)
    rule_parts << "service name=\"#{r.service}\""                      if property_is_set?(:service)
    rule_parts << "port port=\"#{r.port}\" protocol=\"#{r.protocol}\"" if property_is_set?(:port)
    rule_parts << "tcp-mss-clamp value=\"#{r.tcp_mss_clamp}\""         if property_is_set?(:tcp_mss_clamp)
    rule_parts << "icmp-block name=\"#{r.icmp_block}\""                if property_is_set?(:icmp_block)
    rule_parts << 'masquerade'                                         if property_is_set?(:masquerade)
    rule_parts << "icmp-type name=\"#{r.icmp_type}\""                  if property_is_set?(:icmp_type)

    if property_is_set?(:protocol) &&
       !(property_is_set?(:port) || property_is_set?(:forward_port) || property_is_set?(:source_port))
      rule_parts << "protocol value=\"#{r.protocol}\""
    end

    if property_is_set?(:forward_port)
      rule_parts << "forward-port port=\"#{r.forward_port}\" protocol=\"#{r.protocol}\""
      rule_parts << "to-port=\"#{r.to_port}\""    if property_is_set?(:to_port)
      rule_parts << "to-addr=\"#{r.to_address}\"" if property_is_set?(:to_address)
    end

    rule_parts << "source-port port=\"#{r.source_port}\" protocol=\"#{r.protocol}\"" if property_is_set?(:source_port)

    if property_is_set?(:log)
      rule_parts << 'log'
      rule_parts << "prefix=\"#{r.log_prefix}\""     if property_is_set?(:log_prefix)
      rule_parts << "level=\"#{r.log_level}\""       if property_is_set?(:log_level)
      rule_parts << "limit value=\"#{r.log_limit}\"" if property_is_set?(:log_limit)
    end

    if property_is_set?(:nflog)
      rule_parts << 'nflog'
      rule_parts << "group=\"#{r.nflog_group}\""           if property_is_set?(:nflog_group)
      rule_parts << "prefix=\"#{r.nflog_prefix}\""         if property_is_set?(:nflog_prefix)
      rule_parts << "queue-size=\"#{r.nflog_queue_size}\"" if property_is_set?(:nflog_queue_size)
      rule_parts << "limit value=\"#{r.nflog_limit}\""     if property_is_set?(:nflog_limit)
    end

    if property_is_set?(:audit)
      rule_parts << 'audit'
      rule_parts << "limit value=\"#{r.audit_limit}\"" if property_is_set?(:audit_limit)
    end

    if property_is_set?(:rule_action)
      rule_parts << r.rule_action.to_s

      rule_parts << "type=\"#{r.reject_type}\""  if property_is_set?(:reject_type)
      rule_parts << "set=\"#{r.mark_set}\""      if property_is_set?(:mark_set)
      rule_parts << "limit value=\"#{r.action_limit}\"" if property_is_set?(:action_limit)
    end

    rule_parts.join(' ')
  end
end
