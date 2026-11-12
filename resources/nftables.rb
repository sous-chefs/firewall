# frozen_string_literal: true

unified_mode true

include FirewallCookbook::Helpers
include FirewallCookbook::Helpers::Nftables

provides :nftables,
         os: 'linux'

property :rules,
         Hash,
         default: {}
property :input_policy,
         String,
         equal_to: %w(drop accept),
         default: 'accept'
property :output_policy,
         String,
         equal_to: %w(drop accept),
         default: 'accept'
property :forward_policy,
         String,
         equal_to: %w(drop accept),
         default: 'accept'
property :table_ip_nat,
         [true, false],
         default: false
property :table_ip6_nat,
         [true, false],
         default: false
property :nftables_conf_path, String,
         description: 'nftables.conf filepath',
         default: lazy { default_nftables_conf_path }

action :install do
  package 'nftables' do
    action :install
  end
  new_resource.delayed_action :rebuild
end

action :rebuild do
  ensure_default_rules_exist(new_resource)

  file new_resource.nftables_conf_path do
    content <<~NFT
      #!/usr/sbin/nft -f
      flush ruleset
      #{build_rule_file(new_resource.rules)}
    NFT
    mode '0750'
    owner 'root'
    group 'root'
    verify 'nft --check --file %{path}'
    notifies :restart, 'systemd_unit[nftables.service]'
  end

  systemd_unit 'nftables.service' do
    action [:enable, :start]
  end
end

action :restart do
  systemd_unit 'nftables.service' do
    action :restart
  end
end

action :disable do
  systemd_unit 'nftables.service' do
    action [:disable, :stop]
  end
end

action :delete do
  systemd_unit 'nftables.service' do
    action [:disable, :stop]
  end
  file new_resource.nftables_conf_path do
    action :delete
  end
  package 'nftables' do
    action :remove
  end
end
