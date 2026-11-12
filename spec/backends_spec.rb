# frozen_string_literal: true

require 'spec_helper'

describe 'firewall backend rendering' do
  platform 'ubuntu', '24.04'
  step_into :firewall_rule, :firewall_backend_ufw, :firewall_backend_iptables

  context 'UFW rules' do
    recipe do
      rule = firewall_rule 'https' do
        port 443
        action :nothing
      end
      firewall_backend_ufw 'default' do
        rule_resources [rule]
        action :restart
      end
    end
    it { is_expected.to render_file('/etc/default/ufw-chef.rules').with_content('ufw allow in proto tcp to any port 443 from any comment "https"') }
  end

  context 'iptables IPv4 and IPv6 rules' do
    recipe do
      https = firewall_rule 'https' do
        port 443
        action :nothing
      end
      v6 = firewall_rule 'ipv6 only' do
        source '2001:db8::1'
        port 80
        action :nothing
      end
      firewall_backend_iptables 'default' do
        rule_resources [https, v6]
        action :restart
      end
    end
    it { is_expected.to render_file('/etc/iptables/rules.v4').with_content(/--dports 443/) }
    it { is_expected.to render_file('/etc/iptables/rules.v6').with_content(%r{2001:db8::1/128}) }
    it { is_expected.not_to render_file('/etc/iptables/rules.v4').with_content(/2001:db8::1/) }
  end

  context 'a redirect rule' do
    recipe do
      redirect = firewall_rule 'redirect' do
        direction :pre
        port 5555
        redirect_port 6666
        command :redirect
        action :nothing
      end
      firewall_backend_iptables 'default' do
        rule_resources [redirect]
        action :restart
      end
    end
    it { is_expected.to render_file('/etc/iptables/rules.v4').with_content(/\*nat.*-A PREROUTING.*--dports 5555.*--to-ports 6666/m) }
    it { is_expected.not_to render_file('/etc/iptables/rules.v4').with_content(/-t nat/) }
  end

  context 'an empty IPv4-only ruleset' do
    recipe do
      firewall_backend_iptables 'default' do
        ipv6_enabled false
        action :restart
      end
    end
    it { is_expected.to render_file('/etc/iptables/rules.v4').with_content(":INPUT DROP\n") }
    it { is_expected.not_to create_file('/etc/iptables/rules.v6') }
  end

  context 'removing the last NAT rule' do
    before do
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:read).and_call_original
      allow(::File).to receive(:exist?).with('/etc/iptables/rules.v4').and_return(true)
      allow(::File).to receive(:read).with('/etc/iptables/rules.v4').and_return("*nat\n-A PREROUTING -p tcp --dport 5555 -j REDIRECT --to-ports 6666\nCOMMIT\n")
    end
    recipe do
      firewall_backend_iptables 'default' do
        ipv6_enabled false
        action :restart
      end
    end
    it { is_expected.to render_file('/etc/iptables/rules.v4').with_content(/\*nat\n.*:PREROUTING ACCEPT.*COMMIT\n/m) }
    it { is_expected.not_to render_file('/etc/iptables/rules.v4').with_content(/5555/) }
  end

  context 'disabling a custom table policy' do
    before do
      allow(::File).to receive(:exist?).and_call_original
      allow(::File).to receive(:read).and_call_original
      allow(::File).to receive(:foreach).and_call_original
      allow(::File).to receive(:exist?).with('/etc/iptables/rules.v4').and_return(true)
      allow(::File).to receive(:read).with('/etc/iptables/rules.v4').and_return("*mangle\n:FORWARD DROP\n:custom -\nCOMMIT\n")
      allow(::File).to receive(:foreach).with('/etc/iptables/rules.v4').and_yield("*mangle\n").and_yield(":FORWARD DROP\n").and_yield(":custom -\n")
    end
    recipe do
      firewall_backend_iptables 'default' do
        ipv6_enabled false
        action :disable
      end
    end
    it { is_expected.to run_execute('allow default iptables mangle FORWARD').with(command: %w(iptables -t mangle -P FORWARD ACCEPT)) }
    it { is_expected.not_to run_execute('allow default iptables mangle custom') }
  end
end

describe 'firewall dispatch and rule registration' do
  platform 'ubuntu', '24.04'
  step_into :firewall, :firewall_rule, :firewall_backend_ufw, :firewall_backend_iptables

  context 'default UFW backend' do
    recipe do
      firewall 'default'
      firewall_rule 'ignored' do
        port 9999
        only_if { false }
      end
    end
    it { is_expected.to install_package('ufw') }
    it { is_expected.to render_file('/etc/default/ufw').with_content('DEFAULT_INPUT_POLICY="DROP"') }
    it { expect(chef_run.firewall('default').rule_resources).to be_empty }
  end

  context 'explicit iptables backend' do
    recipe do
      firewall 'default' do
        backend :iptables
      end
    end
    it { is_expected.to install_package('iptables-persistent') }
    it { is_expected.to enable_systemd_unit('netfilter-persistent.service') }
    it { expect(chef_run.firewall('default').rule_resources.map(&:protocol)).to eq([:none, :'ipv6-icmp']) }
  end
end

describe 'firewalld package removal' do
  platform 'ubuntu', '24.04'
  step_into :firewalld
  recipe do
    firewalld 'default' do
      action :delete
    end
  end
  it { is_expected.to stop_systemd_unit('firewalld.service') }
  it { is_expected.to remove_package('firewalld') }
end

describe 'nftables rendering' do
  platform 'debian', '12'
  step_into :nftables, :nftables_rule
  recipe do
    nftables 'default' do
      action :nothing
    end
    nftables_rule 'vrrp' do
      protocol 112
      direction :forward
    end
    nftables_rule 'ipv6 set' do
      source ['2001:db8::1', '2001:db8::2']
      dport 443
    end
  end
  it 'preserves a numeric protocol instead of allowing all protocols' do
    expect(chef_run.nftables('default').rules.keys).to include('add rule inet filter FORWARD meta l4proto 112 accept comment "vrrp"')
  end
  it 'renders address arrays as an IPv6 set' do
    expect(chef_run.nftables('default').rules.keys).to include('add rule inet filter INPUT ip6 saddr { 2001:db8::1/128, 2001:db8::2/128 } tcp dport 443 accept comment "ipv6 set"')
  end
end

describe 'Windows firewall rendering' do
  platform 'windows', '2019'
  step_into :firewall_backend_windows
  recipe do
    rule = firewall_rule 'https' do
      port 443
      action :nothing
    end
    firewall_backend_windows 'default' do
      rule_resources [rule]
      action :restart
    end
  end
  it 'retains the rule port and firewall policy' do
    content = chef_run.find_resources(:file).last.content
    expect(content).to include('localport=443', 'set currentprofile firewallpolicy blockinbound,allowoutbound')
  end

  { 'single' => [443, '443'], 'range' => [50000..50002, '50000-50002'], 'array' => [[443, 8443], '443,8443'] }.each do |name, (ports, expected)|
    context "outbound #{name} shorthand" do
      recipe do
        rule = firewall_rule 'outbound' do
          direction :out
          port ports
          action :nothing
        end
        firewall_backend_windows 'default' do
          rule_resources [rule]
          action :restart
        end
      end
      it 'keeps the destination port restriction instead of allowing every port' do
        content = chef_run.find_resources(:file).last.content
        expect(content).to include("remoteport=#{expected} action=allow")
        expect(content).not_to include('remoteport=any')
      end
    end
  end

  { 112 => 112, 6 => 6, 17 => 17, icmp: :icmpv4, :'ipv6-icmp' => :icmpv6,
    icmpv6: :icmpv6, none: :any, esp: 50, ah: 51, ipv6: 41 }.each do |input, expected|
    context "protocol #{input}" do
      recipe do
        rule = firewall_rule 'protocol' do
          protocol input
          port 443 if [6, 17].include?(input)
          action :nothing
        end
        firewall_backend_windows 'default' do
          rule_resources [rule]
          action :restart
        end
      end
      it 'renders a valid protocol and only compatible port predicates' do
        content = chef_run.find_resources(:file).last.content
        expect(content).to include("protocol=#{expected} ")
        if [6, 17].include?(input)
          expect(content).to include('localport=443')
        else
          expect(content).not_to include('localport=', 'remoteport=')
        end
      end
    end
  end

  context 'incompatible protocol and port' do
    recipe do
      rule = firewall_rule 'invalid' do
        protocol 112
        port 443
        action :nothing
      end
      firewall_backend_windows 'default' do
        rule_resources [rule]
        action :restart
      end
    end
    it 'rejects the desired rule before applying firewall changes' do
      expect { chef_run }.to raise_error(ArgumentError, /Windows port constraints require TCP or UDP/)
    end
  end
end
