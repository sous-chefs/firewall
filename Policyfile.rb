# frozen_string_literal: true

name 'firewall'
run_list 'test::default'
cookbook 'firewall', path: '.'
cookbook 'test', path: './test/cookbooks/test'

%w(default firewalld ufw iptables windows).each do |suite|
  named_run_list suite.to_sym, 'test::default'
end
named_run_list :nftables, 'test::nftables'
named_run_list :firewalld_dbus, 'test::firewalld_dbus'

named_run_list :delete, 'test::delete'
named_run_list :dbus_delete, 'test::dbus_delete'
named_run_list :nftables_delete, 'test::nftables_delete'
named_run_list :disable, 'test::disable'
named_run_list :nat_remove, 'test::nat_remove'
named_run_list :custom_policy, 'test::custom_policy'
