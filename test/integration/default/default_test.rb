# InSpec test for recipe xe_insightvm::default

# The InSpec reference, with examples and extensive documentation, can be
# found at https://docs.chef.io/inspec/resources/

require_relative 'spec_helper'

describe firewalld do
  it { should be_enabled }
  it { should be_running }
  only_if { firewalld? }
end

describe service('iptables') do
  it { should be_enabled }
  it { should be_running }
  only_if { iptables }
end

describe service('ufw') do
  it { should be_enabled }
  it { should be_running }
  only_if { os.debian? }
end

describe command('netsh advfirewall show currentprofile firewallpolicy | findstr "Firewall Policy"') do
  its(:stdout) { should match('BlockInbound,AllowOutbound') }
  only_if { os.windows? }
end
