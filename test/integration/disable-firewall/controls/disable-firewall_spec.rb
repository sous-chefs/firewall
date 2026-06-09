require_relative '../../helpers/spec_helper'

describe service('firewalld') do
  it { should_not be_installed }
  it { should_not be_enabled }
  it { should_not be_running }
end if firewalld?

describe service('iptables') do
  it { should_not be_installed }
  it { should_not be_enabled }
  it { should_not be_running }
end if iptables?

describe service('ufw') do
  it { should_not be_installed }
  it { should_not be_enabled }
  it { should_not be_running }
end if os.debian?

describe command('netsh advfirewall show currentprofile firewallpolicy | findstr "Firewall Policy"') do
  its(:stdout) { should match('AllowInbound,AllowOutbound') }
end if os.windows?
