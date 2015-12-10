# these tests only for redhat with iptables
require 'spec_helper'

expected_rules = [
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 22 -m comment --comment 'allow world to ssh' -j ACCEPT},
  %r{ipv4 filter INPUT 50 -m state --state RELATED,ESTABLISHED -m comment --comment established -j ACCEPT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 22 -m comment --comment ssh22 -j ACCEPT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 2200,2222 -m comment --comment ssh2222 -j ACCEPT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234 -m comment --comment temp1 -j DROP},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1235 -m comment --comment temp2 -j REJECT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove -j ACCEPT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove2 -j DROP},
  %r{ipv4 filter INPUT 50 -p 112 -m comment --comment protocolnum -j ACCEPT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1111 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 5431,5432 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv4 filter INPUT 49 -s 192.168.99.99/32 -p tcp -m tcp -m comment --comment block-192.168.99.99 -j REJECT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1000:1100 -m comment --comment range -j ACCEPT},
  %r{ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234,5000:5100,5678 -m comment --comment array -j ACCEPT},
  # ipv6
  %r{ipv6 filter INPUT 50 -m state --state RELATED,ESTABLISHED -m comment --comment established -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p ipv6-icmp -m comment --comment ipv6_icmp -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 22 -m comment --comment ssh22 -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 2200,2222 -m comment --comment ssh2222 -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234 -m comment --comment temp1 -j DROP},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1235 -m comment --comment temp2 -j REJECT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove2 -j DROP},
  %r{ipv6 filter INPUT 50 -p 112 -m comment --comment protocolnum -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1111 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 5431,5432 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv6 filter INPUT 50 -s 2001:db8::ff00:42:8329/128 -p tcp -m tcp -m multiport --dports 80 -m comment --comment ipv6-source -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1000:1100 -m comment --comment range -j ACCEPT},
  %r{ipv6 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1234,5000:5100,5678 -m comment --comment array -j ACCEPT}
]

describe command('firewall-cmd --permanent --direct --get-all-rules'), if: firewalld? do
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end

  # we try to get firewall to add this rule twice, but we expect to see it once!
  duplicate_rule1 = "ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1111 -m comment --comment 'same comment' -j ACCEPT"
  its(:stdout) { should count_occurences(duplicate_rule1, 1) }

  duplicate_rule2 = "ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 5431,5432 -m comment --comment 'same comment' -j ACCEPT"
  its(:stdout) { should count_occurences(duplicate_rule2, 1) }
end

describe command('firewall-cmd --direct --get-all-rules'), if: firewalld? do
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end

  # we try to get firewall to add this rule twice, but we expect to see it once!
  duplicate_rule1 = "ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 1111 -m comment --comment 'same comment' -j ACCEPT"
  its(:stdout) { should count_occurences(duplicate_rule1, 1) }

  duplicate_rule2 = "ipv4 filter INPUT 50 -p tcp -m tcp -m multiport --dports 5431,5432 -m comment --comment 'same comment' -j ACCEPT"
  its(:stdout) { should count_occurences(duplicate_rule2, 1) }
end

describe service('firewalld'), if: firewalld? do
  it { should be_enabled }
  it { should be_running }
end
