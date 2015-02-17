[:ubuntu, :debian].each do |platform|
  Chef::Platform.set(
      :platform => platform,
      :resource => :firewall_rule,
      :provider => Chef::Provider::FirewallRuleUfw
  )
  Chef::Platform.set(
    :platform => platform,
    :resource => :firewall,
    :provider => Chef::Provider::FirewallUfw
  )
end
package 'ufw' do
  action :install
end
