
node.override['firewall']['windows']['defaults'] = {
  policy: {
    input: 'blockinbound',
    output: 'blockoutbound'
  }
}
