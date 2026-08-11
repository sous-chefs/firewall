
expected_rules = [
  %r{ 22/tcp + ALLOW IN +Anywhere},
  %r{ 2200,2222/tcp + ALLOW IN +Anywhere},
  %r{ 1234/tcp + DENY IN +Anywhere},
  %r{ 1235/tcp + REJECT IN +Anywhere},
  %r{ 1236/tcp + DENY IN +Anywhere},
  %r{ Anywhere + REJECT IN +192.168.99.99/tcp},
  %r{ 80/tcp + ALLOW IN +2001:db8::ff00:42:8329},
  %r{ 1000:1100/tcp + ALLOW IN +Anywhere},
  %r{ 1234,5000:5100,5678/tcp + ALLOW IN +Anywhere},
  %r{ 192.168.2.1 25/tcp + ALLOW IN + 192.168.1.1},
  /# ssh22/,
]

describe command('ufw status numbered') do
  its(:stdout) { should match(/Status: active/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe service('ufw') do
  it { should be_installed }
  it { should be_enabled }
  describe command('ufw status 2>&1') do
    its(:stdout) { should match(/Status: active/) }
  end
end

if os.name == 'ubuntu'
  describe file('/opt/firewall-ufw-replay-test/replay-recovered') do
    it { should exist }
    its('content') { should match(/replay retried successfully/) }
  end

  describe file('/etc/default/ufw-chef.rules') do
    its('content') { should match(%r{ufw allow 54321/tcp}) }
  end

  describe command('ufw status numbered') do
    its('stdout') { should match(%r{54321/tcp +ALLOW IN}) }
  end
end
