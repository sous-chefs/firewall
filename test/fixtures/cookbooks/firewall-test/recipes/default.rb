include_recipe 'firewall'

firewall 'ufw' do
  action :enable
end

firewall_rule 'ssh22' do
  port 22
  action :allow
end

firewall_rule 'ssh2222' do
  port 2222
  action :allow
end

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
