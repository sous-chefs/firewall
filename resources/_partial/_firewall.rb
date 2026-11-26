# frozen_string_literal: true

property :enabled, [true, false], default: true
property :log_level, Symbol, equal_to: %i(low medium high full off), default: :low
property :rules, Hash, default: {}
property :rule_resources, Array, default: [], desired_state: false
property :ipv6_enabled, [true, false], default: true
property :package_options, String
property :input_policy, String, default: 'DROP'
property :forward_policy, String, default: 'DROP'
property :output_policy, String, default: 'ACCEPT'
property :ruleset, Hash
property :ufw_defaults, Hash, default: {
  ipv6: 'yes', manage_builtins: 'no', ipt_sysctl: '/etc/ufw/sysctl.conf',
  ipt_modules: 'nf_conntrack_ftp nf_nat_ftp nf_conntrack_netbios_ns',
  policy: { input: 'DROP', output: 'ACCEPT', forward: 'DROP', application: 'SKIP' }
}
property :windows_input_policy, String, default: 'blockinbound'
property :windows_output_policy, String, default: 'allowoutbound'
