unified_mode true

require 'ipaddr'

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Nftables

  def return_early?(new_resource)
    !new_resource.notify_firewall ||
      !(new_resource.action.include?(:create) &&
        !new_resource.should_skip?(:create))
  end
end

provides :nftables_rule
default_action :create

property :firewall_name,
         String,
         default: 'default'
property :command,
         [Array, Symbol],
         default: :accept
property :protocol,
         [Integer, Symbol],
         default: :tcp,
         callbacks: {
           'must be either :tcp, :udp, :icmp, :\'ipv6-icmp\', :icmpv6, :none, or a valid IP protocol number' => lambda do |p|
             %i(udp tcp icmp icmpv6 ipv6-icmp esp ah ipv6 none).include?(p) || (0..142).include?(p)
           end,
         }
property :direction,
         Symbol,
         equal_to: [:in, :out, :pre, :post, :forward],
         default: :in
# nftables handles ip6 and ip simultaneously.  Except for directions
# :pre and :post, where where either :ip6 or :ip must be specified.
# callback should prevent from mixing that up.
property :family,
         Symbol,
         equal_to: [:ip6, :ip],
         default: :ip
property :source,
         [String, Array],
         callbacks: {
           'must be a valid ip address' => lambda do |ips|
             Array(ips).inject(false) do |a, ip|
               a || !!IPAddr.new(ip)
             end
           end,
         }
property :sport,
         [Integer, String, Array, Range]
property :interface,
         String

property :dport,
         [Integer, String, Array, Range]
property :destination,
         [String, Array],
         callbacks: {
           'must be a valid ip address' => lambda do |ips|
             Array(ips).inject(false) do |a, ip|
               a || !!IPAddr.new(ip)
             end
           end,
         }
property :outerface,
         String

property :position,
         Integer,
         default: 50
property :stateful,
         [Symbol, Array]
property :redirect_port,
         Integer
property :description,
         String,
         name_property: true
property :include_comment,
         [true, false],
         default: true
property :log_prefix,
         String
property :log_group,
         Integer
# for when you just want to pass a raw rule
property :raw,
         String

# do you want this rule to notify the firewall to recalculate
# (and potentially reapply) the firewall_rule(s) it finds?
property :notify_firewall,
         [true, false],
         default: true

action :create do
  return if return_early?(new_resource)
  fwr = build_firewall_rule(new_resource)

  with_run_context :root do
    edit_resource!('nftables', new_resource.firewall_name) do |fw_rule|
      r = rules.dup || {}
      r.merge!({
                 fwr => fw_rule.position,
               })
      rules(r)
      delayed_action :rebuild
    end
  end
end
