#########
# firewall
#########
Chef::Platform.set platform: :ubuntu, resource: :firewall, provider: Chef::Provider::FirewallIptables

#########
# firewall_rule
#########
Chef::Platform.set platform: :ubuntu, resource: :firewall_rule, provider: Chef::Provider::FirewallRuleIptables
