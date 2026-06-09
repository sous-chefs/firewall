firewall 'default' do
  backend :nftables
end

firewall_rule 'allow loopback' do
  interface 'lo'
  protocol :none
end

firewall_rule 'allow icmp' do
  protocol :icmp
end

firewall_rule 'allow world to ssh' do
  port 22
  source '0.0.0.0/0'
  command [:log, :accept]
  log_group 0
end

firewall_rule 'allow world to mosh' do
  protocol :udp
  port 60000..61000
  source '0.0.0.0/0'
end

# allow established connections
firewall_rule 'established' do
  stateful [:related, :established]
  protocol :none # explicitly don't specify protocol
end

# ipv6 needs ICMP to reliably work, so ensure it's enabled if ipv6
firewall_rule 'ipv6_icmp' do
  protocol :'ipv6-icmp'
end

firewall_rule 'ssh22' do
  port 22
  command [:log, :accept]
  log_prefix 'TEST_PREFIX:'
end

firewall_rule 'ssh2222' do
  port [2222, 2200]
  command [:log, :counter, :accept]
end

# other rules
firewall_rule 'temp1' do
  port 1234
  command :drop
end

firewall_rule 'temp2' do
  port 1235
  command :reject
end

firewall_rule 'addremove' do
  port 1236
end

firewall_rule 'addremove2' do
  port 1236
  command :drop
end

firewall_rule 'protocolnum' do
  protocol 112
end

firewall_rule 'prepend' do
  port 7788
  position 5
end

bad_ip = '192.168.99.99'
firewall_rule "block-#{bad_ip}" do
  source bad_ip
  position 49
  command :reject
end

firewall_rule 'ipv6-source' do
  port 80
  source '2001:db8::ff00:42:8329'
end

firewall_rule 'range' do
  port 1000..1100
end

firewall_rule 'array' do
  port [1234, 5000..5100, '5678']
end

firewall_rule 'RPC Port Range In' do
  port 5000..5100
  protocol :tcp
  direction :in
end

firewall_rule 'HTTP HTTPS' do
  port [80, 443]
  protocol :tcp
  direction :out
end

nftables_rule 'native nftables ports and outerface' do
  direction :out
  sport 1024
  dport 8443
  outerface 'eth0'
end

firewall_rule 'dport2433' do
  description 'This should not be included'
  include_comment false
  source '127.0.0.0/8'
  port 2433
  direction :in
end

firewall_rule 'esp' do
  protocol :esp
end

firewall_rule 'ah' do
  protocol :ah
end

firewall_rule 'esp-ipv6' do
  source '::'
  protocol :esp
end

firewall_rule 'ah-ipv6' do
  source '::'
  protocol :ah
end

firewall_rule 'redirect' do
  direction :pre
  port 5555
  redirect_port 6666
  command :redirect
end
