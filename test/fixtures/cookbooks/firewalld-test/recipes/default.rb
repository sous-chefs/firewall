firewalld 'default'

firewalld_config 'set some values' do
  default_zone 'home'
  log_denied 'all'
end

firewalld_zone 'home' do
  icmp_block_inversion true
  interfaces ['eth0']
  forward false
end

firewalld_zone 'ztest' do
  description 'Test zone'
  forward true
  forward_ports [['8080', 'tcp', '80', '192.0.2.1']]
  icmp_block_inversion true
  icmp_blocks %w(echo-reply echo-request network-unreachable)
  interfaces %w(eth1337 eth2337)
  masquerade true
  ports [%w(23 udp)]
  protocols ['udp']
  rules_str ['rule family=ipv4 source address=192.168.0.14 accept']
  services ['ssh']
  source_ports [%w(23 udp)]
  sources ['192.0.2.2']
  target 'ACCEPT'
  version '1'
end

firewalld_policy 'ptest' do
  description 'Policy for testing'
  egress_zones ['dmz']
  forward_ports [['8080', 'tcp', '80', '192.0.2.1']]
  ingress_zones ['home']
  masquerade false
  ports [%w(23 udp)]
  priority 10
  protocols ['udp']
  rich_rules ['rule family=ipv4 source address=192.168.0.14 accept']
  services ['ssh']
  source_ports [%w(23 udp)]
  target 'ACCEPT'
  version '42'
end

firewalld_service 'ssh2' do
  version '1'
  description 'ssh on obscure port'
  ports [%w(2222 tcp)]
  destination({ 'ipv4' => '192.0.2.0', 'ipv6' => '::1' })
  protocols ['udp']
  source_ports [%w(23 tcp)]
  includes ['ssh']
  helpers ['tftp']
end

firewalld_icmptype 'rick-rolled' do
  version '1'
  description 'never gonna give you up'
  destinations %w(ipv4 ipv6)
end

firewalld_ipset 'example-ips' do
  version '1'
  description 'some ips as an example ipset'
  type 'hash:ip'
  options({
    'family' => 'inet',
    # timeout is not applicable for permanent configuration
    # 'timeout' => '12',
    'hashsize' => '1000',
    'maxelem' => '255',
  })
  entries ['192.0.2.16', '192.0.2.32']
end

firewalld_ipset 'single-ip' do
  description 'Test if String is coerced to an array'
  type 'hash:ip'
  options({ 'family' => 'inet6' })
  entries '::1'
end

firewalld_helper 'example-helper' do
  version '1'
  description 'Example of a firewalld_helper'
  family 'ipv6'
  nf_module 'nf_conntrack_irc'
  ports [%w(6667 tcp)]
end

firewalld_helper 'description-helper' do
  nf_module 'nf_conntrack_irc'
end
