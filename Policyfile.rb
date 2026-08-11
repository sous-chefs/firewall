# frozen_string_literal: true

name 'firewall'

run_list 'firewall::default', 'firewall-test::default'

cookbook 'apt', git: 'https://github.com/sous-chefs/apt.git', branch: 'main'
cookbook 'firewall', path: '.'
cookbook 'firewall-test', path: './test/fixtures/cookbooks/firewall-test'
cookbook 'firewalld-test', path: './test/fixtures/cookbooks/firewalld-test'
cookbook 'nftables-test', path: './test/fixtures/cookbooks/nftables-test'

named_run_list :default, 'firewall::default', 'firewall-test::default'
named_run_list :firewalld_simple, 'firewall::default', 'firewall-test::default'
named_run_list :ufw, 'firewall::default', 'firewall-test::default'
named_run_list :iptables, 'firewall::default', 'firewall-test::default'
named_run_list :nftables, 'nftables-test::default'
named_run_list :firewalld_advanced, 'firewalld-test::default'
named_run_list :windows, 'firewall::default', 'firewall-test::default'
