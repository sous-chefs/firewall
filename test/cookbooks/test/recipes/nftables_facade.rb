# frozen_string_literal: true

proof = '/var/tmp/firewall-nftables-facade-verified'
path = platform_family?('debian') ? '/etc/nftables.conf' : '/etc/sysconfig/nftables.conf'

# Exercise the façade with the package already installed.
package 'nftables'

managed_firewall = firewall 'facade' do
  backend :nftables
  allow_loopback true
  allow_ssh true
end

managed_rule = firewall_rule 'facade managed traffic' do
  firewall_name 'facade'
  command [:log, :counter, :accept]
  log_prefix 'facade:'
  log_group 0
  port(::File.exist?(proof) ? 9443 : 8443)
end

firewall_rule 'facade IPv6 family' do
  firewall_name 'facade'
  protocol :ipv6
end

ruby_block 'verify nftables reload and rejected configuration' do
  block do
    managed_firewall.run_action(:restart)
    marker = "#{path}.chef-applied"
    old_config = ::File.binread(path)
    old_marker = ::File.binread(marker)
    file_metadata = lambda do
      stat = ::File.stat(path)
      [stat.mode, stat.uid, stat.gid]
    end
    old_metadata = file_metadata.call
    active_timestamp = lambda do
      command = Mixlib::ShellOut.new('systemctl', 'show', 'nftables.service', '-p', 'ActiveEnterTimestampMonotonic', '--value').run_command
      command.error!
      command.stdout.strip
    end
    before_reload = active_timestamp.call
    raise 'nftables was not active' unless before_reload.to_i.positive?

    old_rules = managed_firewall.rules
    begin
      managed_firewall.rules(old_rules.merge('invalid nftables statement' => 100))
      managed_firewall.run_action(:restart)
      raise 'invalid nftables configuration reached the system'
    rescue Chef::Exceptions::ValidationFailed => error
      raise unless error.message.include?('failed verification')
    ensure
      managed_firewall.rules(old_rules)
    end
    unless ::File.binread(path) == old_config && ::File.binread(marker) == old_marker && file_metadata.call == old_metadata
      raise 'invalid nftables candidate changed the active configuration metadata or marker'
    end

    managed_rule.port(9443)
    managed_firewall.run_action(:restart)
    raise 'updating nftables restarted the active unit' unless active_timestamp.call == before_reload

    live = Mixlib::ShellOut.new('nft', 'list', 'ruleset').run_command
    live.error!
    raise 'The active nftables rules did not change' unless live.stdout.include?('dport 9443') && !live.stdout.include?('dport 8443')
    raise 'The applied nftables marker was not updated' unless ::File.binread(marker) != old_marker

    ::File.write(proof, "verified active reload and invalid configuration rejection\n")
  end
  not_if { ::File.exist?(proof) }
end
