require_relative '../../helpers/spec_helper'

describe service('firewalld') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end if firewalld?

describe service('iptables') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end if iptables?

describe service('ufw') do
  it { should be_installed }
  it { should be_enabled }
  describe command('ufw status 2>&1') do
    its(:stdout) { should match(/Status: active/) }
  end
end if os.debian?

describe command('netsh advfirewall show currentprofile firewallpolicy | findstr "Firewall Policy"') do
  its(:stdout) { should match('BlockInbound,AllowOutbound') }
end if os.windows?
