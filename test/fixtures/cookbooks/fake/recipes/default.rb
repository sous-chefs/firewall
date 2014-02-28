include_recipe 'firewall'

firewall 'ufw' do
  action :enable
end

firewall_rule 'ssh' do
  port 22
  action :allow
end
