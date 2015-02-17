class Chef
  class Resource::Firewall < Resource
    include Poise(container: true)
    provides :firewall_rule

    actions(:enable, :disable, :flush)
    attribute(:log_level, :kind_of => [Symbol, String], :equal_to => [:low, :medium, :high, :full, 'low', 'medium', 'high', 'full'], :default => :low)
  end
end
