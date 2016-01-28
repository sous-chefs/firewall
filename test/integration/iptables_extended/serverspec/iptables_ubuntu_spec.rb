require 'spec_helper'

expected_rules = [
  # we included the .*-j so that we don't bother testing comments
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 22 .*-j ACCEPT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 2200,2222 .*-j ACCEPT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1234 .*-j DROP},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1235 .*-j REJECT},
  %r{-A INPUT -p tcp -m tcp -m multiport --dports 1236 .*-j DROP},
  %r{-A INPUT -s 192.168.99.99(/32)? -p tcp -m tcp .*-j REJECT},
  %r{-A POSTROUTING .*-d 172.28.128.21.* -j SNAT --to-source 172.28.128.6}
]

describe command('iptables-save'), if: ubuntu? do
  its(:stdout) { should match(/COMMIT/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe service('iptables-persistent'), if: ubuntu? do
  it { should be_enabled }
end

describe file('/etc/iptables/rules.v4'), if: ubuntu? do
  it { should be_file }

  expected_rules.each do |r|
    its(:content) { should match(r) }
  end
end
