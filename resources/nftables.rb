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
    notifies :rebuild, "nftables[#{new_resource.name}]"
  end
end

action :rebuild do
  ensure_default_rules_exist(new_resource)

  file new_resource.nftables_conf_path do
    content  <<~NFT
      #!/usr/sbin/nft -f
      flush ruleset
      #{build_rule_file(new_resource.rules)}
    NFT
    mode '0750'
    owner 'root'
    group 'root'
    notifies :restart, 'service[nftables]'
  end

  service 'nftables' do
    action [:enable, :start]
  end
end

action :restart do
  service 'nftables' do
    action :restart
  end
end

action :disable do
  service 'nftables' do
    action [:disable, :stop]
  end
end
