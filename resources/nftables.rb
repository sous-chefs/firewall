unified_mode true

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Nftables
end

provides :nftables,
         os: 'linux'

property :rules,
         Hash,
         default: {}
property :input_policy,
         String,
         equal_to: ['drop', 'accept'],
         default: 'accept'
property :output_policy,
         String,
         equal_to: ['drop', 'accept'],
         default: 'accept'
property :forward_policy,
         String,
         equal_to: ['drop', 'accept'],
         default: 'accept'
property :table_ip_nat,
         [true, false],
         default: false
property :table_ip6_nat,
         [true, false],
         default: false


action :install do
  package 'nftables' do
    action :install
    notifies :rebuild, "nftables[#{new_resource.name}]"
  end
end

action :rebuild do
  ensure_default_rules_exist(new_resource)

  file '/etc/nftables.conf' do
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
