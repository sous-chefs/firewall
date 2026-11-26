# frozen_string_literal: true

require 'digest'

unified_mode true

include FirewallCookbook::Helpers
include FirewallCookbook::Helpers::Nftables

provides :nftables,
         os: 'linux'

property :rules,
         Hash,
         default: {}
property :filter_family, Symbol, equal_to: %i(inet ip), default: :inet, desired_state: false
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
property :reload_on_rebuild, [true, false],
         default: false,
         desired_state: false,
         description: 'Internal: use the packaged unit reload and track successful facade reconciliation'

action :install do
  package 'nftables' do
    action :install
  end
  new_resource.delayed_action :rebuild
end

action :rebuild do
  ensure_default_rules_exist(new_resource)

  desired = <<~NFT
    #!/usr/sbin/nft -f
    flush ruleset
    #{build_rule_file(new_resource.rules)}
  NFT
  applied_hash = "#{Digest::SHA256.hexdigest(desired)}\n"
  marker = "#{new_resource.nftables_conf_path}.chef-applied"
  reload_on_rebuild = new_resource.reload_on_rebuild

  configuration = file new_resource.nftables_conf_path do
    content desired
    mode '0750'
    owner 'root'
    group 'root'
    verify 'nft --check --file %{path}'
    notifies :restart, 'systemd_unit[nftables.service]' unless reload_on_rebuild
  end

  # Reload replaces the live rules atomically. The packaged stop action flushes them separately.
  if reload_on_rebuild
    systemd_unit "reload #{new_resource.name} nftables rules" do
      unit_name 'nftables.service'
      action :reload
      only_if 'systemctl is-active --quiet nftables.service'
      only_if do
        configuration.updated_by_last_action? || !::File.exist?(marker) || ::File.read(marker) != applied_hash
      end
    end
  end

  systemd_unit 'nftables.service' do
    action [:enable, :start]
  end

  # A failed reload or start leaves the previous marker, so the next run retries.
  if reload_on_rebuild
    file marker do
      content applied_hash
      mode '0600'
      owner 'root'
      group 'root'
    end
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
  if new_resource.reload_on_rebuild
    file "#{new_resource.nftables_conf_path}.chef-applied" do
      action :delete
    end
  end
  package 'nftables' do
    action :remove
  end
end
