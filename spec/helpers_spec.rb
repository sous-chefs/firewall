# frozen_string_literal: true

require 'spec_helper'
require_relative '../libraries/helpers'
require_relative '../libraries/helpers_nftables'
require_relative '../libraries/helpers_firewalld_dbus'

describe 'firewall helper regressions' do
  it 'handles numeric protocols when deciding the IP family' do
    helper = Class.new { include FirewallCookbook::Helpers }.new
    rule = Struct.new(:source, :destination, :protocol).new(nil, nil, 112)
    expect(helper.ipv6_rule?(rule)).to be false
  end

  it 'renders an nftables log prefix with frozen strings enabled' do
    helper = Class.new { include FirewallCookbook::Helpers::Nftables }.new
    rule = Struct.new(:log_prefix, :direction, :log_group).new('audit:', :in, 0)
    expect(helper.nftables_command_log(rule)).to include('prefix "audit:"', 'group 0')
  end

  it 'preserves an IPv6 forward-port destination' do
    helper = Class.new { include FirewallCookbook::Helpers::FirewalldDBus }.new
    expect(helper.parse_forward_ports('port=443:proto=tcp:toport=8443:toaddr=2001:db8::1')).to eq(['443', 'tcp', '8443', '2001:db8::1'])
  end

  it 'compares rich-rule quoting without swapping source and destination' do
    helper = Class.new { include FirewallCookbook::Helpers::FirewalldDBus }.new
    expect(helper.same_rich_rules?(['rule family="ipv4" source address="192.0.2.1" accept'], ['rule family=ipv4 source address=192.0.2.1 accept'])).to be true
    expect(helper.same_rich_rules?(['rule source address="192.0.2.1" destination address="192.0.2.2" accept'], ['rule source address=192.0.2.2 destination address=192.0.2.1 accept'])).to be false
  end
end

describe 'Windows firewall status' do
  before { require_relative '../libraries/helpers_windows' }
  let(:helper) { Class.new { include FirewallCookbook::Helpers::Windows }.new }

  it 'recognises normal padded netsh output' do
    allow(helper).to receive(:shell_out!).with('netsh advfirewall show currentprofile').and_return(double(stdout: "State                                 ON\r\n"))
    expect(helper.active?).to be true
  end

  it 'recognises a disabled profile' do
    allow(helper).to receive(:shell_out!).with('netsh advfirewall show currentprofile').and_return(double(stdout: "State                                 OFF\r\n"))
    expect(helper.active?).to be false
  end
end
