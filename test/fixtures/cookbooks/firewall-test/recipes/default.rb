
firewalld = rhel? || amazon_linux?
iptables = !firewalld && node['firewall']['ubuntu_iptables']
ufw = !firewalld && !iptables

include_recipe 'firewall'

firewall_rule 'ssh22' do
  port 22
  command :allow
end

firewall_rule 'ssh2222' do
  port [2222, 2200]
  command :allow
end

# other rules
firewall_rule 'temp1' do
  port 1234
  command :deny
end

firewall_rule 'temp2' do
  port 1235
  command :reject
end

firewall_rule 'addremove' do
  port 1236
  command :allow
  only_if { rhel? || amazon_linux? || node['firewall']['ubuntu_iptables'] } # don't do this on ufw, will reset ufw on every converge
end

firewall_rule 'addremove2' do
  port 1236
  command :deny
end

firewall_rule 'protocolnum' do
  protocol 112
  command :allow
  not_if { ufw } # debian ufw doesn't support protocol numbers
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
  command :allow
end

firewall_rule 'range' do
  port 1000..1100
  command :allow
end

firewall_rule 'array' do
  port [1234, 5000..5100, '5678']
  command :allow
end

if firewalld
  firewall_rule 'allow 5672 in internal zone' do
    zone 'internal'
    port 5672
  end
end

if ufw
  firewall_rule 'ufw raw test' do
    raw 'allow from 192.168.1.1 to 192.168.2.1 port 25 proto tcp'
  end
end

if iptables
  firewall_rule 'RPC Port Range In' do
    port 5000..5100
    protocol :tcp
    command :allow
    direction :in

    # # centos 5 is broken for ipv6 ranges
    # # see https://github.com/chef-cookbooks/firewall/pull/111#issuecomment-163520156
    # not_if { rhel? && node['platform_version'].to_f < 6.0 }
  end
  firewall_rule 'HTTP HTTPS' do
    port [80, 443]
    protocol :tcp
    direction :out
    command :allow
  end

  firewall_rule 'port2433' do
    description 'This should not be included'
    include_comment false
    source    '127.0.0.0/8'
    port      2433
    direction :in
    command   :allow
  end
end

include_recipe 'firewall-test::windows' if windows?
