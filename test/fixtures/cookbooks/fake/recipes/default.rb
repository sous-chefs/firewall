firewall 'ufw' do
  action :enable
end

firewall_rule 'allow world to ssh' do
  port        22
  source      '0.0.0.0/0'
  action      [:allow]
end
