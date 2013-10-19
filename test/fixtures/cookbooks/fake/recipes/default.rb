include_recipe "firewall::ufw"

firewall 'ufw' do
  action :enable
end
