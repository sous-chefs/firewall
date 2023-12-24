# these tests only for redhat with iptables
expected_rules = [
  /ipv4 filter INPUT 50 -i lo -m comment --comment 'allow loopback' -j ACCEPT/,
  /ipv4 filter INPUT 50 -p icmp -m comment --comment 'allow icmp' -j ACCEPT/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 22 -m comment --comment 'allow world to ssh' -j ACCEPT/,
  /ipv4 filter INPUT 50 -m state --state RELATED,ESTABLISHED -m comment --comment established -j ACCEPT/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 22 -m comment --comment ssh22 -j ACCEPT/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 2200,2222 -m comment --comment ssh2222 -j ACCEPT/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234 -m comment --comment temp1 -j DROP/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1235 -m comment --comment temp2 -j REJECT/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove -j ACCEPT/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove2 -j DROP/,
  /ipv4 filter INPUT 50 -p 112 -m comment --comment protocolnum -j ACCEPT/,
  %r{ipv4 filter INPUT 49 -s 192.168.99.99/32 -p tcp -m tcp -m comment --comment block-192.168.99.99 -j REJECT},
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1000:1100 -m comment --comment range -j ACCEPT/,
  /ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234,5000:5100,5678 -m comment --comment array -j ACCEPT/,
  # ipv6
  /ipv6 filter INPUT 50 -i lo -m comment --comment 'allow loopback' -j ACCEPT/,
  /ipv6 filter INPUT 50 -p icmp -m comment --comment 'allow icmp' -j ACCEPT/,
  /ipv6 filter INPUT 50 -m state --state RELATED,ESTABLISHED -m comment --comment established -j ACCEPT/,
  /ipv6 filter INPUT 50 -p ipv6-icmp -m comment --comment ipv6_icmp -j ACCEPT/,
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 22 -m comment --comment ssh22 -j ACCEPT/,
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 2200,2222 -m comment --comment ssh2222 -j ACCEPT/,
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234 -m comment --comment temp1 -j DROP/,
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1235 -m comment --comment temp2 -j REJECT/,
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove -j ACCEPT/,
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove2 -j DROP/,
  /ipv6 filter INPUT 50 -p 112 -m comment --comment protocolnum -j ACCEPT/,
  %r{ipv6 filter INPUT 50 -s 2001:db8::ff00:42:8329/128 -p tcp -m tcp -m multiport --dports 80 -m comment --comment ipv6-source -j ACCEPT},
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1000:1100 -m comment --comment range -j ACCEPT/,
  /ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234,5000:5100,5678 -m comment --comment array -j ACCEPT/,
]

describe command('firewall-cmd --permanent --direct --get-all-rules') do
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe command('firewall-cmd --direct --get-all-rules') do
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe service('firewalld') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
