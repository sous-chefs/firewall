expected_rules = [
  %r(-A INPUT -p tcp -m tcp -m state --state RELATED,ESTABLISHED -j ACCEPT),
  %r(-A INPUT -p tcp -m tcp --dport 22 -j ACCEPT),
  %r(-A INPUT -p tcp -m tcp --dport 2222 -j ACCEPT),
  %r(-A INPUT -p tcp -m tcp --dport 2200 -j ACCEPT),
  %r(-A INPUT -p tcp -m tcp --dport 1234 -j DROP),
  %r(-A INPUT -p tcp -m tcp --dport 1235 -j REJECT --reject-with icmp-port-unreachable),
  %r(-A INPUT -p tcp -m tcp --dport 1236 -j DROP),
]

describe command('iptables-save') do
  its(:stdout) { should match(/COMMIT/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
