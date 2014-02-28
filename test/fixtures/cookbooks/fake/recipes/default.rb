include_recipe 'firewall'

firewall 'ufw' do
  action :enable
end
