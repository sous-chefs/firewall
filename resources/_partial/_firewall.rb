# frozen_string_literal: true

unified_mode true

default_action :install

property :backend,
         Symbol,
         equal_to: [:firewalld, :iptables, :nftables, :ufw, :windows],
         description: 'Firewall backend to manage. Defaults to the platform family default.'
property :enabled,
         [true, false],
         default: true,
         description: 'Set to false to leave this resource as a no-op.'
property :log_level,
         Symbol,
         equal_to: [:low, :medium, :high, :full, :off],
         default: :low,
         description: 'UFW logging level.'
property :rules,
         Hash,
         default: {},
         description: 'Internal rule accumulator used by firewall_rule resources.'
property :ipv6_enabled,
         [true, false],
         default: true,
         description: 'Manage IPv6 rules where the backend supports them.'
property :package_options,
         String,
         description: 'Pass additional options to the package manager when installing the firewall.'
property :allow_ssh,
         [true, false],
         default: false,
         description: 'Create a default inbound SSH allow rule.'
property :allow_winrm,
         [true, false],
         default: false,
         description: 'Create a default inbound WinRM allow rule.'
property :allow_mosh,
         [true, false],
         default: false,
         description: 'Create a default inbound Mosh allow rule.'
property :allow_loopback,
         [true, false],
         default: false,
         description: 'Create the legacy iptables loopback allow rule.'
property :allow_icmp,
         [true, false],
         default: false,
         description: 'Create the legacy iptables ICMP allow rule.'
property :allow_established,
         [true, false],
         default: true,
         description: 'Create the legacy iptables established connection allow rules.'
property :iptables_ruleset,
         Hash,
         default: {
           '*filter' => 1,
           ':INPUT DROP' => 2,
           ':FORWARD DROP' => 3,
           ':OUTPUT ACCEPT' => 4,
           'COMMIT_FILTER' => 100,
         },
         description: 'Base iptables ruleset merged before firewall_rule-generated rules.'
property :ufw_defaults,
         Hash,
         default: {
           ipv6: 'yes',
           manage_builtins: 'no',
           ipt_sysctl: '/etc/ufw/sysctl.conf',
           ipt_modules: 'nf_conntrack_ftp nf_nat_ftp nf_conntrack_netbios_ns',
           policy: {
             input: 'DROP',
             output: 'ACCEPT',
             forward: 'DROP',
             application: 'SKIP',
           },
         },
         description: 'Settings rendered to /etc/default/ufw.'
property :windows_policy,
         Hash,
         default: {
           input: 'blockinbound',
           output: 'allowoutbound',
         },
         description: 'Windows current-profile firewall policy.'
