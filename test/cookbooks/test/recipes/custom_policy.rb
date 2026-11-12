# frozen_string_literal: true

firewall 'default' do
  backend :iptables
  allow_established false
  ruleset('*filter' => 1, ':INPUT ACCEPT' => 2, ':OUTPUT ACCEPT' => 3,
          ':FORWARD ACCEPT' => 4, 'COMMIT_FILTER' => 100,
          '*mangle' => 101, ':PREROUTING ACCEPT' => 102, ':INPUT ACCEPT [0:0]' => 103,
          ':FORWARD DROP' => 104, ':OUTPUT ACCEPT [0:0]' => 105,
          ':POSTROUTING ACCEPT' => 106, 'COMMIT_MANGLE' => 200)
end
