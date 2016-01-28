# override the default ruleset with more tables
node.override['firewall']['iptables']['defaults'] = {
  '*nat' => 101,
  ':PREROUTING ACCEPT' => 102,
  ':POSTROUTING ACCEPT' => 103,
  ':OUTPUT ACCEPT' => 104,
  'COMMIT' => 200,
}

include_recipe 'chef-sugar'
include_recipe 'firewall-test'

firewall_rule "postroute" do
  raw "-A POSTROUTING -o eth1 -p tcp -d 172.28.128.21 -j SNAT --to-source 172.28.128.6"
  position 150
end
