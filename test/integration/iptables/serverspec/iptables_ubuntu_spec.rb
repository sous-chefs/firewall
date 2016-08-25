require 'spec_helper'

expected_rules = [
  # we included the .*-j so that we don't bother testing comments
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 22 .*-j ACCEPT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 2200,2222 .*-j ACCEPT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1234 .*-j DROP},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1235 .*-j REJECT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1236 .*-j DROP},
  %r{-A INPUT -s 192.168.99.99(/32)? -p tcp -m tcp .*-j REJECT}
]

expected_ipv6_rules = [
  %r{-A INPUT -p ipv6-icmp .* -j ACCEPT},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 22 .*-j ACCEPT},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 2200,2222 .*-j ACCEPT},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 1234 .*-j DROP},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 1235 .*-j REJECT},
  %r{-A INPUT( -s ::/0 -d ::/0)? -p tcp -m tcp -m multiport --dports 1236 .*-j DROP},
  %r{-A INPUT -s 2001:db8::ff00:42:8329/128( -d ::/0)? -p tcp -m tcp -m multiport --dports 80 .*-j ACCEPT}
]

describe command('iptables-save'), if: ubuntu? do
  its(:stdout) { should match(/COMMIT/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe command('ip6tables-save'), if: ubuntu? do
  its(:stdout) { should match(/COMMIT/) }

  expected_ipv6_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe service('iptables-persistent'), if: iptables_persistent? do
  it { should be_enabled }
end

describe service('netfilter-persistent'), if: netfilter_persistent? do
  it { should be_enabled }
end

describe file('/etc/iptables/rules.v4'), if: ubuntu? do
  it { should be_file }

  expected_rules.each do |r|
    its(:content) { should match(r) }
  end
end

describe file('/etc/iptables/rules.v6'), if: ubuntu? do
  it { should be_file }

  expected_ipv6_rules.each do |r|
    its(:content) { should match(r) }
  end
end
