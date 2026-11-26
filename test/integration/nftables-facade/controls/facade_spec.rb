# frozen_string_literal: true

describe service('nftables') do
  it { should be_enabled }
  it { should be_running }
end

describe command('nft list ruleset') do
  its(:exit_status) { should eq 0 }
  its(:stdout) { should match(/tcp dport 9443 log prefix "facade:" group 0 counter.*accept/) }
  its(:stdout) { should match(/meta nfproto ipv6 accept comment "facade IPv6 family"/) }
  its(:stdout) { should_not match(/dport 8443/) }
end

describe file('/var/tmp/firewall-nftables-facade-verified') do
  its(:content) { should include('verified active reload and invalid configuration rejection') }
end
