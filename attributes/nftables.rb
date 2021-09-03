default['firewall']['nftables']['defaults'][:policy] = {
  input: 'drop',
  forward: 'drop',
  output: 'accept',
}
default['firewall']['nftables']['defaults'][:ruleset] = {
  'add table inet filter' => 1,
  'add table ip6 nat' => 1,
  'add table ip nat' => 1,
  "add chain inet filter INPUT { type filter hook input priority 0 ; policy #{node['firewall']['nftables']['defaults']['policy']['input']}; }" => 2,
  "add chain inet filter OUTPUT { type filter hook output priority 0 ; policy #{node['firewall']['nftables']['defaults']['policy']['output']}; }" => 2,
  "add chain inet filter FOWARD { type filter hook forward priority 0 ; policy #{node['firewall']['nftables']['defaults']['policy']['forward']}; }" => 2,
  'add chain ip nat POSTROUTING { type nat hook postrouting priority 100 ;}' => 2,
  'add chain ip nat PREROUTING { type nat hook prerouting priority -100 ;}' => 2,
  'add chain ip6 nat POSTROUTING { type nat hook postrouting priority 100 ;}' => 2,
  'add chain ip6 nat PREROUTING { type nat hook prerouting priority -100 ;}' => 2,
}

default['firewall']['ubuntu_iptables'] = false
default['firewall']['redhat7_iptables'] = false
default['firewall']['allow_established'] = true
default['firewall']['ipv6_enabled'] = true
