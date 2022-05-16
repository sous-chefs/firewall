expected_rules = [
  /^table inet filter {$/,
  /\s+type filter hook output priority.*/,
  /\s+type filter hook forward priority.*/,
  /\s+type filter hook input priority filter; policy drop;/,
  /\s+tcp dport 7788 accept.*/,
  /\s+ip saddr 192.168.99.99 reject.*/,
  /\s+iif "lo" accept comment "allow loopback"/,
  /\s+icmp type echo-request accept.*$/,
  /\s+tcp dport 22 log prefix "INPUT:" group 0 accept.*$/,
  /\s+udp dport 60000-61000 accept.*$/,
  /\s+ct state established,related accept.*$/,
  /\s+icmpv6 type { echo-request, nd-router-solicit, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept.*$/,
  /\s+tcp dport 22 log prefix "TEST_PREFIX:" accept.*$/,
  /\s+tcp dport { 2200, 2222 } log prefix "INPUT:" counter packets \d+ bytes \d+ accept.*$/,
  /\s+tcp dport 1234 drop.*$/,
  /\s+tcp dport 1235 reject.*$/,
  /\s+tcp dport 1236 drop.*$/,
  /\s+ip6 saddr 2001:db8::ff00:42:8329 tcp dport 80 accept.*$/,
  /\s+tcp dport 1000-1100 accept.*$/,
  /\s+tcp dport { 1234, 5000-5100, 5678 } accept.*$/,
  /\s+tcp dport 5000-5100 accept.*$/,
  %r{\s+ip saddr 127.0.0.0/8 tcp dport 2433 accept.*$},
  /\s+ip protocol esp accept.*$/,
  /\s+ip protocol ah accept.*$/,
  /\s+ip6 nexthdr esp accept.*$/,
  /\s+ip6 nexthdr ah accept.*$/,
]

describe command('nft list ruleset') do
  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end

describe service('nftables') do
  it { should be_installed }
  it { should be_enabled }
  it { should be_running }
end
