include_recipe 'chef-sugar'
include_recipe 'firewall'

firewall 'default' do
  action :enable
end

# do SSH rules before enabling firewall
firewall_rule 'established' do
  stateful 'RELATED,ESTABLISHED'
  action :allow
  only_if { rhel? } # debian ufw already does this by default, can't modify it
end

firewall_rule 'ssh22' do
  port 22
  action :allow
end

firewall_rule 'ssh2222' do
  port [2222, 2200]
  action :allow
end

# other rules
firewall_rule 'temp1' do
  port 1234
  action :deny
end

firewall_rule 'temp2' do
  port 1235
  action :reject
end

firewall_rule 'addremove' do
  port 1236
  action :allow
end

firewall_rule 'addremove2' do
  port 1236
  action :deny
end

# something to check for duplicates
(0..1).each do |i|
  firewall_rule "duplicate#{i}" do
    port 1111
    action :allow
    description 'same comment'
  end

  firewall_rule "duplicate#{i}" do
    port [5432, 5431]
    action :allow
    description 'same comment'
  end
end
