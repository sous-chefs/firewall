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

