firewall_rule 'logging' do
  command :log
  logging :droppedconnections
end
