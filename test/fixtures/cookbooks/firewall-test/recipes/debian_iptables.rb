#########
# firewall
#########
Chef::Platform.set platform: :ubuntu, resource: :firewall, provider: Chef::Provider::FirewallIptables

#########
# firewall_rule
#########
Chef::Platform.set platform: :ubuntu, resource: :firewall_rule, provider: Chef::Provider::FirewallRuleIptables

log 'save iptables rules' do
  level :debug
  notifies :save, 'firewall[default]', :delayed
end
