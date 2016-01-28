# these tests only for redhat with iptables
require 'spec_helper'

expected_rules = [
  # we included the .*-j so that we don't bother testing comments
  %r{-A INPUT -m state --state RELATED,ESTABLISHED .*-j ACCEPT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 22 .*-j ACCEPT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 2200,2222 .*-j ACCEPT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1234 .*-j DROP},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1235 .*-j REJECT --reject-with icmp-port-unreachable},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1236 .*-j DROP},
  %r{-A INPUT -p vrrp .*-j ACCEPT},
  %r{-A INPUT -s 192.168.99.99(/32)? -p tcp -m tcp .*-j REJECT --reject-with icmp-port-unreachable},
  %r{-A POSTROUTING -d 172.28.128.21/32 -o eth1 -p tcp -j SNAT --to-source 172.28.128.6}
]

expected_ipv6_rules = []

describe command('iptables-save'), if: redhat? do
  its(:stdout) { should match(/COMMIT/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end

  # we try to get firewall to add this rule twice, but we expect to see it once!
  duplicate_rule1 = '-A INPUT -p tcp -m tcp -m multiport --dports 1111 -m comment --comment "same comment" -j ACCEPT'
  its(:stdout) { should count_occurences(duplicate_rule1, 1) }

  duplicate_rule2 = '-A INPUT -p tcp -m tcp -m multiport --dports 5431,5432 -m comment --comment "same comment" -j ACCEPT'
  its(:stdout) { should count_occurences(duplicate_rule2, 1) }
end

describe service('iptables'), if: redhat? do
  it { should be_enabled }
  it { should be_running }
end
