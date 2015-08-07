Chef::Platform.set platform: :ubuntu, resource: :firewall, provider: Chef::Provider::FirewallIptablesUbuntu
Chef::Platform.set platform: :ubuntu, resource: :firewall_rule, provider: Chef::Provider::FirewallRuleIptablesUbuntu
node.override['firewall_test_iptables'] = true
