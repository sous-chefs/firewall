expected_rules = [
  # we included the .*-j so that we don't bother testing comments
  %r(-A INPUT -p tcp -m tcp -m state --state RELATED,ESTABLISHED .*-j ACCEPT),
  %r(-A INPUT -p tcp -m tcp -m multiport --dports 22 .*-j ACCEPT),
  %r(-A INPUT -p tcp -m tcp -m multiport --dports 2222 .*-j ACCEPT),
  %r(-A INPUT -p tcp -m tcp -m multiport --dports 2200 .*-j ACCEPT),
  %r(-A INPUT -p tcp -m tcp -m multiport --dports 1234 .*-j DROP),
  %r(-A INPUT -p tcp -m tcp -m multiport --dports 1235 .*-j REJECT --reject-with icmp-port-unreachable),
  %r(-A INPUT -p tcp -m tcp -m multiport --dports 1236 .*-j DROP),
]

describe command('iptables-save') do
  its(:stdout) { should match(/COMMIT/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
