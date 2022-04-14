#
# Cookbook Name:: firewall
# Resource:: nftables
#
# Copyright 2022 GSI Helmholtzzentrum fuer Schwerionenforschung GmbH
#
# Authors:
#  Matthias Pausch (m.pausch@gsi.de)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
# This code is an adjustment of https://github.com/sous-chefs/firewall
#

action_class do
  include FirewallCookbook::Helpers
  include FirewallCookbook::Helpers::Nftables
end

unified_mode true

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
