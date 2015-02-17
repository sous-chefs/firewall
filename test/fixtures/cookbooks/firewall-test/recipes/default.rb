include_recipe 'firewall'

firewall 'default' do
  action :enable
end

# do SSH rules before enabling firewall
firewall_rule 'established' do
  stateful 'RELATED,ESTABLISHED'
  action :allow
end

firewall_rule 'ssh22' do
  dest_port 22
  action :allow
end

firewall_rule 'ssh2222' do
  dest_port 2222
  action :allow
end

firewall_rule 'ssh2200' do
  dest_port 2200
  action :allow
end

# other rules
firewall_rule 'temp1' do
  dest_port 1234
  action :deny
end

firewall_rule 'temp2' do
  dest_port 1235
  action :reject
end

firewall_rule 'addremove' do
  dest_port 1236
  action :allow
end

firewall_rule 'addremove2' do
  dest_port 1236
  action :deny
end
