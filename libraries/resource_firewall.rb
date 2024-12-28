class Chef
  class Resource::Firewall < Chef::Resource::LWRPBase
    resource_name(:firewall)
    provides(:firewall)
    actions(:install, :restart, :disable, :flush)
    default_action(:install)

    attribute(:enabled, kind_of: [TrueClass, FalseClass], default: true)

    attribute(:log_level, kind_of: Symbol, equal_to: [:low, :medium, :high, :full, :off], default: :low)
    attribute(:rules, kind_of: Hash)

    # for firewall implementations where ipv6 can be skipped (currently iptables-specific)
    attribute(:ipv6_enabled, kind_of: [TrueClass, FalseClass], default: true)

    # allow override of package options for firewalld package
    attribute(:package_options, kind_of: String, default: nil)
  end
end
