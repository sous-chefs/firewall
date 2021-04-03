default['firewall']['firewalld']['permanent'] = false
default['firewall']['firewalld']['zone'] = 'drop'

default['firewall']['firewalld']['loopback_zone'] = 'trusted'
default['firewall']['firewalld']['icmp_zone'] = 'public'
default['firewall']['firewalld']['ssh_zone'] = 'public'
default['firewall']['firewalld']['mosh_zone'] = 'public'
default['firewall']['firewalld']['established_zone'] = 'public'
