include_recipe 'chef-sugar'
include_recipe 'firewall'

node.override['firewall']['windows']['defaults'] = {
  policy: {
    input: 'blockinbound',
    output: 'blockoutbound'
  }
}
node.override['firewall']['windows']['default_rules'] = false

firewall_rule 'Outgoing_Rule_0' do
  command :allow
  dest_port 8080
  direction :out
  position 1
  protocol :tcp
end

firewall_rule 'Incoming_Rule_1' do
  command :allow
  dest_port 5985
  direction :in
  position 2
  protocol :tcp
end

firewall_rule 'Incoming_Rule_2' do
  command :allow
  dest_port 5985
  direction :in
  position 3
  protocol :udp
end

firewall_rule 'Incoming_Rule_3' do
  command :allow
  dest_port 5986
  direction :in
  position 4
  protocol :tcp
end

firewall_rule 'Incomingt_Rule_4' do
  command :allow
  dest_port 3389
  direction :in
  position 5
  protocol :tcp
end

firewall_rule 'Incomingt_Rule_5' do
  command :allow
  dest_port 80
  direction :in
  position 6
  protocol :tcp
end

firewall_rule 'logging' do
  command :log
  logging :droppedconnections
end
