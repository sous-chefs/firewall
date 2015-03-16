expected_rules = [
  %r( 22/tcp + ALLOW IN + Anywhere),
  %r( 2222/tcp + ALLOW IN + Anywhere),
  %r( 1234/tcp + DENY IN + Anywhere),
  %r( 1235/tcp + REJECT IN + Anywhere),
  %r( 1236/tcp + DENY IN + Anywhere)
]

describe command('ufw status numbered') do
  its(:stdout) { should match(/Status: active/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
