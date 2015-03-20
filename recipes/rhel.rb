if node['platform_version'].to_i < 7
  [:redhat, :centos].each do |platform|
    Chef::Platform.set(
      :platform => platform,
      :resource => :firewall,
      :provider => Chef::Provider::FirewallIptables
    )
    Chef::Platform.set(
      :resource => :firewall_rule,
      :provider => Chef::Provider::FirewallRuleIptables
    )
  end
  package 'iptables' do
    action :install
  end
else
  [:redhat, :centos].each do |platform|
    Chef::Platform.set(
      :platform => platform,
      :resource => :firewall,
      :provider => Chef::Provider::FirewallFirewalld
    )
    Chef::Platform.set(
      :resource => :firewall_rule,
      :provider => Chef::Provider::FirewallRuleFirewalld
    )
  end
  package 'firewalld' do
    action :install
  end
end
