apt_update do
  only_if { platform?('debian') }
end

firewalld 'default'

firewalld_config 'set some values' do
  default_zone 'home'
  log_denied 'all'
end

firewalld_helper 'example-helper' do
  version '1'
  description 'Example of a firewalld_helper'
  family 'ipv6'
  nf_module 'nf_conntrack_irc'
  ports ['6667/tcp', '5556/udp']
end

firewalld_helper 'minimal-helper' do
  nf_module 'nf_conntrack_netbios_ns'
  ports '7777/udp'
end

firewalld_helper 'change-minimal-helper' do
  short 'minimal-helper'
  ports '7778/udp'
end

firewalld_icmptype 'rick-rolled' do
  version '1'
  description 'never gonna give you up'
  destinations %w(ipv4 ipv6)
end

firewalld_icmptype 'change-rick-rolled' do
  short 'rick-rolled'
  destinations 'ipv4'
end

firewalld_icmptype 'minimal-icmptype'

firewalld_icmptype 'change-minimal-icmptype' do
  short 'minimal-icmptype'
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

firewalld_ipset 'change-example-ips' do
  short 'example-ips'
  entries ['192.0.2.16', '192.0.2.32']
end

firewalld_ipset 'single-ip' do
  entries '192.0.2.22'
end

firewalld_policy 'ptest' do
  description 'Policy for testing'
  egress_zones 'dmz'
  forward_ports [
    'port=8081:proto=tcp:toport=81:toaddr=192.0.2.1',
    'port=8084-8085:proto=tcp:toport=84-85:toaddr=192.0.2.5',
  ]
  ingress_zones 'home'
  masquerade false
  ports '23/udp'
  priority 10
  protocols 'udp'
  rich_rules 'rule family=ipv4 source address=192.168.0.14 accept'
  services 'ssh'
  source_ports '23/udp'
  target 'ACCEPT'
  version '41'
end

firewalld_policy 'pminimal' do
  egress_zones 'external'
  ingress_zones 'internal'
  masquerade true
end

firewalld_policy 'change-pminimal' do
  short 'pminimal'
  masquerade false
end

firewalld_service 'ssh2' do
  version '1'
  description 'ssh on obscure port'
  ports '2222/tcp'
  destination({ 'ipv4' => '192.0.2.0', 'ipv6' => '::1' })
  #  module_names 'nf_conntrack_netbios_ns'
  protocols 'udp'
  source_ports '23/tcp'
  includes 'ssh'
  helpers 'tftp'
end

firewalld_service 'minimal-service' do
  ports '2/tcp'
end

firewalld_service 'change-minimal-service' do
  short 'minimal-service'
  ports '1/udp'
end

firewalld_zone 'home' do
  icmp_block_inversion true
  interfaces 'eth0'
  forward false
end

firewalld_zone 'ztest' do
  description 'Test zone'
  forward true
  forward_ports 'port=8080:proto=tcp:toport=80:toaddr=192.0.2.1'
  icmp_block_inversion true
  icmp_blocks %w(echo-reply echo-request network-unreachable)
  interfaces %w(eth1337 eth2337)
  masquerade true
  ports '23/udp'
  protocols 'udp'
  rules_str 'rule family=ipv4 source address=192.168.0.14 accept'
  services 'ssh'
  source_ports '23/udp'
  sources '192.0.2.2'
  target 'ACCEPT'
  version '1'
end

firewalld_zone 'ztest2' do
  sources '192.0.2.0/24'
  version '1'
end
