# frozen_string_literal: true

solution = (node.dig('firewall_test', 'solution') || case node['platform_family']
                                                     when 'debian'
                                                       platform?('debian') ? 'nftables' : 'ufw'
                                                     when 'amazon', 'fedora', 'rhel', 'suse'
                                                       'firewalld'
                                                     when 'windows'
                                                       'windows'
                                                     else
                                                       'iptables'
                                                     end).to_sym
firewalld = solution == :firewalld
iptables = solution == :iptables
nftables = solution == :nftables
ufw = solution == :ufw

# UFW provided by opt-in EPEL repository on RHEL platforms
package 'epel-release' do
  only_if { ufw && platform_family?('rhel') }
end

# The package resource on Fedora is broken until this is installed.
# Just a Test Kitchen issue?
execute 'install-python3-dnf' do
  command 'dnf install -y python3-dnf'
  not_if 'python3 -c "import dnf"'
  only_if { platform_family?('fedora') }
  action :run
end

# Workaround for a bug when using firewalld:
# * Debian: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=1074789
# * Ubuntu: https://bugs.launchpad.net/ubuntu/+source/policykit-1/+bug/2054716
user 'polkitd' do
  system true
  only_if { firewalld && platform?('debian', 'ubuntu') }
end

package 'firewalld' do
  only_if { firewalld }
end

execute 'use iptables firewalld backend in dokken' do
  command "sed -i -e 's/^FirewallBackend=.*/FirewallBackend=iptables/' /etc/firewalld/firewalld.conf"
  only_if { firewalld && ::File.exist?('/.dockerenv') && ::File.exist?('/etc/firewalld/firewalld.conf') }
  not_if "grep -q '^FirewallBackend=iptables$' /etc/firewalld/firewalld.conf"
end

firewall 'default' do
  solution solution
  allow_ssh true
  allow_winrm true
  allow_mosh true
  allow_loopback true
  allow_icmp true
  windows_policy(
    input: 'blockinbound',
    output: 'blockoutbound'
  )
end

firewall_rule 'ssh22' do
  port 22
  command :allow
end

firewall_rule 'ssh2222' do
  port [2222, 2200]
  command :allow
end

firewall_rule 'dest_port' do
  dest_port 25
  command :allow
end

firewall_rule 'source_port' do
  source_port 31000
  command :allow
end

# other rules
firewall_rule 'temp1' do
  port 1234
  command :deny
end

firewall_rule 'temp2' do
  port 1235
  command :reject
end

firewall_rule 'addremove' do
  port 1236
  command :allow
  not_if { ufw } # don't do this on ufw, will reset ufw on every converge
end

firewall_rule 'addremove2' do
  port 1236
  command :deny
end

firewall_rule 'vrrp protocol by number' do
  protocol 112
  command :allow
  not_if { ufw } # debian ufw doesn't support protocol numbers
end

firewall_rule 'prepend' do
  port 7788
  position 5
end

bad_ip = '192.168.99.99'
firewall_rule "block-#{bad_ip}" do
  source bad_ip
  position 49
  command :reject
end

firewall_rule 'ipv6-source' do
  port 80
  source '2001:db8::ff00:42:8329'
  command :allow
end

firewall_rule 'range' do
  port 1000..1100
  command :allow
end

firewall_rule 'array' do
  port [1234, 5000..5100, '5678']
  command :allow
end

if firewalld
  firewall_rule 'allow 5672 in internal zone' do
    zone 'internal'
    port 5672
  end
end

if ufw
  firewall_rule 'ufw raw test' do
    raw 'allow from 192.168.1.1 to 192.168.2.1 port 25 proto tcp'
  end
end

if iptables
  firewall_rule 'RPC Port Range In' do
    port 5000..5100
    protocol :tcp
    command :allow
    direction :in
  end

  firewall_rule 'HTTP HTTPS' do
    port [80, 443]
    protocol :tcp
    direction :out
    command :allow
  end

  firewall_rule 'port2433' do
    description 'This should not be included'
    include_comment false
    source    '127.0.0.0/8'
    port      2433
    direction :in
    command   :allow
  end
end

if nftables
  firewall_rule 'redirect' do
    direction :pre
    port 5555
    redirect_port 6666
    command :redirect
  end
end
