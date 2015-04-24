# these tests only for debian/ubuntu with ufw
require_relative 'spec_helper'

expected_rules = [
  %r{ 22/tcp + ALLOW IN +Anywhere},
  %r{ 2200,2222/tcp + ALLOW IN +Anywhere},
  %r{ 1234/tcp + DENY IN +Anywhere},
  %r{ 1235/tcp + REJECT IN +Anywhere},
  %r{ 1236/tcp + DENY IN +Anywhere},
  %r{ Anywhere + REJECT IN +192.168.99.99/tcp},
  %r{ 80/tcp + ALLOW IN +2001:db8::ff00:42:8329}
]

describe command('ufw status numbered'), :if => ufw? do
  its(:stdout) { should match(/Status: active/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end

  # we try to get firewall to add this rule twice, but we expect to see it once! (twice on 12.04)
  its(:stdout) { should count_occurences('1111/tcp ', 2) } # once for ipv4, once for ipv6
  its(:stdout) { should count_occurences('5431,5432/tcp ', 2) } # once for ipv4, once for ipv6
end
