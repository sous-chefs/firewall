default['firewall']['iptables']['defaults'] = {
  policy: {
    input: 'DROP',
    forward: 'DROP',
    output: 'ACCEPT'
  }
}
