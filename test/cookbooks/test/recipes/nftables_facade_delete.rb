# frozen_string_literal: true

firewall 'facade' do
  backend :nftables
  action :disable
end

ruby_block 'check that stopping nftables removes the managed rules' do
  block do
    live = Mixlib::ShellOut.new('nft', 'list', 'ruleset').run_command
    live.error!
    raise 'Managed nftables rules remained after stopping the service' if live.stdout.include?('facade managed traffic')
  end
  only_if { ['/usr/sbin/nft', '/sbin/nft'].any? { |path| ::File.executable?(path) } }
end

firewall 'facade cleanup' do
  backend :nftables
  action :delete
end
