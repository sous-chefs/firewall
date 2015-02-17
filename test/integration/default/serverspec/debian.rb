expected_rules = [
  %r(\[ 1\] 22 + ALLOW IN + Anywhere),
  %r(\[ 2\] 2222 + ALLOW IN + Anywhere),
  %r(\[ 3\] 1234 + DENY IN + Anywhere),
  %r(\[ 4\] 1235 + REJECT IN + Anywhere),
  %r(\[ 5\] 1236 + DENY IN + Anywhere)
]

describe command('ufw status numbered') do
  its(:stdout) { should match(/Status: active/) }

  expected_rules.each do |r|
    its(:stdout) { should match(r) }
  end
end
