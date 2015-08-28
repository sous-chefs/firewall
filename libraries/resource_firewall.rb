class Chef
  class Resource::Firewall < Chef::Resource::LWRPBase
    resource_name(:firewall)
    actions(:install, :restart, :disable, :flush, :save)
    default_action(:install)

    attribute(:disabled, :kind_of => [TrueClass, FalseClass], :default => false)
    attribute(:log_level, :kind_of => Symbol, :equal_to => [:low, :medium, :high, :full], :default => :low)
    attribute(:rules, :kind_of => Hash)

    # for firewalld, specify the zone when firewall is disable and enabled
    attribute(:disabled_zone, :kind_of => Symbol, :default => :public)
    attribute(:enabled_zone, :kind_of => Symbol, :default => :drop)
  end
end
