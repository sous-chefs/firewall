include_recipe "firewall::iptables"

firewall 'iptables' do
  action :enable
end
