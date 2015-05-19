# these tests only for redhat with iptables
require_relative 'spec_helper'

expected_rules = [
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 22 -m comment --comment 'allow world to ssh' -j ACCEPT},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m state --state RELATED,ESTABLISHED -m comment --comment established -j ACCEPT},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 22 -m comment --comment ssh22 -j ACCEPT},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 2222,2200 -m comment --comment ssh2222 -j ACCEPT},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1234 -m comment --comment temp1 -j DROP},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1235 -m comment --comment temp2 -j REJECT},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove -j ACCEPT},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove2 -j DROP},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1111 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 5432,5431 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv4 filter INPUT 1 -s 192.168.99.99/32 -p tcp -m tcp -m comment --comment block-192.168.99.99 -j REJECT},
  # ipv6
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m state --state RELATED,ESTABLISHED -m comment --comment established -j ACCEPT},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 22 -m comment --comment ssh22 -j ACCEPT},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 2222,2200 -m comment --comment ssh2222 -j ACCEPT},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1234 -m comment --comment temp1 -j DROP},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1235 -m comment --comment temp2 -j REJECT},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove -j ACCEPT},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1236 -m comment --comment addremove2 -j DROP},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1111 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv6 filter INPUT 1 -p tcp -m tcp -m multiport --dports 5432,5431 -m comment --comment 'same comment' -j ACCEPT},
  %r{ipv6 filter INPUT 1 -s 2001:db8::ff00:42:8329/128 -p tcp -m tcp -m multiport --dports 80 -m comment --comment ipv6-source -j ACCEPT}
]

describe command('firewall-cmd --direct --get-all-rules'), :if => firewalld? do
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end

  # we try to get firewall to add this rule twice, but we expect to see it once!
  duplicate_rule1 = "ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 1111 -m comment --comment 'same comment' -j ACCEPT"
  its(:stdout) { should count_occurences(duplicate_rule1, 1) }

  duplicate_rule2 = "ipv4 filter INPUT 1 -p tcp -m tcp -m multiport --dports 5432,5431 -m comment --comment 'same comment' -j ACCEPT"
  its(:stdout) { should count_occurences(duplicate_rule2, 1) }
end
