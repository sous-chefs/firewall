# default ruleset for various chains in the *filter table
default['firewall']['iptables']['defaults'] = {
  '*filter' => 1,
  ":INPUT DROP" => 2,
  ":FORWARD DROP" => 3,
  ":OUTPUT ACCEPT" => 4,
  'COMMIT_FILTER' => 100 # anything after COMMIT is stripped
}

# other interesting settings
default['firewall']['ubuntu_iptables'] = false
default['firewall']['redhat7_iptables'] = false
default['firewall']['allow_established'] = true
default['firewall']['ipv6_enabled'] = true
