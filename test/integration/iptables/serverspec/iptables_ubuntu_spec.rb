require 'spec_helper'

expected_rules = [
  # we included the .*-j so that we don't bother testing comments
  /-A INPUT -i lo .*-j ACCEPT/,
  /-A INPUT -p icmp .*-j ACCEPT/,
  /-A INPUT -p tcp -m tcp -m multiport --dports 22 .*-j ACCEPT/,
  /-A INPUT -p tcp -m tcp -m multiport --dports 2200,2222 .*-j ACCEPT/,
  /-A INPUT -p tcp -m tcp -m multiport --dports 1234 .*-j DROP/,
  /-A INPUT -p tcp -m tcp -m multiport --dports 1235 .*-j REJECT/,
  /-A INPUT -p tcp -m tcp -m multiport --dports 1236 .*-j DROP/,
  %r{-A INPUT -s 192.168.99.99(/32)? -p tcp -m tcp .*-j REJECT},
]

expected_ipv6_rules = [
  /-A INPUT -p ipv6-icmp .* -j ACCEPT/,
  /-A INPUT -i lo .*-j ACCEPT/,
  /-A INPUT -p icmp .*-j ACCEPT/,
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 22 .*-j ACCEPT},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 2200,2222 .*-j ACCEPT},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 1234 .*-j DROP},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 1235 .*-j REJECT},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 1236 .*-j DROP},
  %r{-A INPUT -s 2001:db8::ff00:42:8329/128( -d ::/0)? -p tcp -m tcp -m multiport --dports 80 .*-j ACCEPT},
]

describe command('iptables-save'), if: (ubuntu? || debian?) do
  its(:stdout) { should match(/COMMIT/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe command('ip6tables-save'), if: (ubuntu? || debian?) do
  its(:stdout) { should match(/COMMIT/) }

  expected_ipv6_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe service('iptables-persistent'), if: iptables_persistent? do
  it { should be_enabled }
  it { should be_running }
end

describe service('netfilter-persistent'), if: netfilter_persistent? do
  it { should be_enabled }
  it { should be_running }
end

describe file('/etc/iptables/rules.v4'), if: (ubuntu? || debian?) do
  it { should be_file }

  expected_rules.each do |r|
    its(:content) { should match(r) }
  end
end

describe file('/etc/iptables/rules.v6'), if: (ubuntu? || debian?) do
  it { should be_file }

  expected_ipv6_rules.each do |r|
    its(:content) { should match(r) }
  end
end
