# these tests only for redhat with iptables
expected_rules = [
  /rule port port="22" protocol="tcp" accept/,
  /rule port port="2222" protocol="tcp" accept/,
  /rule port port="2200" protocol="tcp" accept/,
  /rule port port="1234" protocol="tcp" accept/,
  /rule port port="1235" protocol="tcp" reject/,
  /rule port port="1236" protocol="tcp" drop/,
  /rule protocol value="112" accept/,
  /rule priority="5" port port="7788" protocol="tcp" accept/,
  /rule priority="49" family="ipv4" source address="192.168.99.99" reject/,
  /rule port port="1000-1100" protocol="tcp" accept/,
  /rule port port="5000-5100" protocol="tcp" accept/,
  /rule port port="5678" protocol="tcp" accept/,
  %r{rule family="ipv4" source address="0.0.0.0/0" port port="60000-61000" protocol="udp" accept},
  %r{rule family="ipv4" source address="0.0.0.0/0" port port="22" protocol="tcp" accept},
  # ipv6
  /rule family="ipv6" source address="2001:db8::ff00:42:8329" port port="80" protocol="tcp" accept/,
]

describe command('firewall-cmd --list-rich-rules') do
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe service('firewalld') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end

# Check for rules not in the default zone
describe command('firewall-cmd --list-rich-rules --zone=internal') do
  its(:stdout) { should match /rule port port="5672" protocol="tcp" accept/ }
end
