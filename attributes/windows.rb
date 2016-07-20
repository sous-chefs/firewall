# Windows platform defult settings: block undefined inbould traffic, allow all outgoing traffic

default['firewall']['windows']['defaults'] = {
  policy: {
    input: 'blockinbound',
    output: 'allowoutbound'
  }
}
