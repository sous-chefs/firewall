default['firewall']['allow_ssh'] = false
default['firewall']['allow_winrm'] = false
default['firewall']['allow_mosh'] = false
default['firewall']['allow_loopback'] = false
default['firewall']['allow_icmp'] = false

default['firewall']['solution'] = {
  'debian'  => 'ufw',
  'amazon'  => 'firewalld',
  'fedora'  => 'firewalld',
  'rhel'    => 'firewalld',
  'suse'    => 'firewalld',
  'windows' => 'windows',
}.fetch(node['platform_family'], 'iptables')
