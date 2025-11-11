
firewalld_zone 'rich-rules'

# Leave this rule in the default zone, i.e. don't use "zone" property, so that
# we test the default zone handling.
firewalld_rich_rule '443/tcp' do
  port 443
  protocol 'tcp'
  audit true
  rule_action :accept
end

firewalld_rich_rule 'Allow SSH service' do
  zone 'rich-rules'
  service 'ssh'
  rule_action :accept
end

firewalld_rich_rule 'Log and accept from 192.168.1.1' do
  zone 'rich-rules'
  source '192.168.1.1'
  log true
  log_prefix 'LOG_PREFIX'
  rule_action :accept
end

firewalld_rich_rule 'Reject traffic from 172.16.0.0/12 with priority' do
  zone 'rich-rules'
  family :ipv4
  source '172.16.0.0/12'
  priority(-10)
  rule_action :reject
end

firewalld_rich_rule 'Accept traffic not from 172.16.2.1' do
  zone 'rich-rules'
  source_not '172.16.2.1'
  rule_action :accept
end

firewalld_rich_rule 'Accept traffic to 10.0.0.0/8' do
  zone 'rich-rules'
  family :ipv4
  destination '10.0.0.0/8'
  rule_action :accept
end

firewalld_rich_rule 'Accept traffic not to 172.16.2.1' do
  zone 'rich-rules'
  destination_not '172.16.2.1'
  rule_action :accept
end

firewalld_rich_rule 'Drop UDP traffic on ports 1000-2000' do
  zone 'rich-rules'
  port '1000-2000'
  protocol 'udp'
  rule_action :drop
end

firewalld_rich_rule 'Audit and accept HTTPS traffic' do
  zone 'rich-rules'
  port 443
  protocol 'tcp'
  audit true
  rule_action :accept
end

firewalld_rich_rule 'Accept ICMP protocol traffic' do
  zone 'rich-rules'
  protocol 'icmp'
  rule_action :accept
end

firewalld_rich_rule 'Block neighbor solicitation ICMP' do
  zone 'rich-rules'
  icmp_block 'neighbour-solicitation'
end

firewalld_rich_rule 'Drop router-advertisement ICMP type' do
  zone 'rich-rules'
  icmp_type 'router-advertisement'
  rule_action :drop
end

firewalld_rich_rule 'Enable masquerading' do
  zone 'rich-rules'
  masquerade true
end

firewalld_rich_rule 'Forward port 8080 to 80' do
  zone 'rich-rules'
  family :ipv4
  forward_port 8080
  protocol 'tcp'
  to_port 80
end

firewalld_rich_rule 'Forward port 5353 to 53 at 10.10.10.10' do
  zone 'rich-rules'
  forward_port 5353
  protocol 'udp'
  to_port 53
  to_address '10.10.10.10'
end

firewalld_rich_rule 'Accept TCP traffic from source port 25' do
  zone 'rich-rules'
  source_port 25
  protocol 'tcp'
  rule_action :accept
end

firewalld_rich_rule 'Log and accept TCP traffic on ports 12000-12999' do
  zone 'rich-rules'
  source_port '12000-12999'
  protocol 'tcp'
  log true
  log_level :info
  log_limit '5/s'
  rule_action :accept
end

firewalld_rich_rule 'Mark FTP traffic with 0x1' do
  zone 'rich-rules'
  service 'ftp'
  rule_action :mark
  mark_set '0x1'
end

firewalld_rich_rule 'Log and accept TFTP traffic from 192.168.0.0/24' do
  zone 'rich-rules'
  source '192.168.0.0/24'
  service 'tftp'
  log true
  log_prefix 'tftp'
  log_level :info
  log_limit '1/m'
  rule_action :accept
end

firewalld_rich_rule 'Accept RADIUS traffic on IPV6' do
  zone 'rich-rules'
  family :ipv6
  service 'radius'
  rule_action :accept
  action_limit '100/m'
end

firewalld_rich_rule 'Forward RADIUS port on IPv6' do
  zone 'rich-rules'
  family :ipv6
  source '1:2:3:4:6::'
  forward_port 4011
  protocol 'tcp'
  to_port 4012
  to_address '1::2:3:4:7'
end

firewalld_rich_rule 'Reject traffic from 192.168.2.3 with ICMP admin prohibited' do
  zone 'rich-rules'
  family :ipv4
  source '192.168.2.3'
  rule_action :reject
  reject_type 'icmp-admin-prohibited'
end

firewalld_rich_rule 'Raw rule' do
  zone 'rich-rules'
  raw 'rule family="ipv6" source address="::1" log prefix="RAW_RULE" accept'
end
