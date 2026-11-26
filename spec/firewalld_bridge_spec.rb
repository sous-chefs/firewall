# frozen_string_literal: true

require 'spec_helper'

describe 'firewalld D-Bus readiness' do
  platform 'ubuntu', '24.04'
  step_into :firewalld
  before { stub_command('firewall-cmd --state').and_return(false) }
  recipe do
    firewalld 'default' do
      action :restart
    end
  end
  it { is_expected.to run_execute('wait for restarted firewalld D-Bus API').with(command: %w(firewall-cmd --state), retries: 30, retry_delay: 1) }

  context 'when the D-Bus service is already ready' do
    before { stub_command('firewall-cmd --state').and_return(true) }
    it { is_expected.not_to run_execute('wait for restarted firewalld D-Bus API') }
  end
end

describe 'firewalld dependency ownership' do
  platform 'amazon', '2023'
  step_into :firewalld
  recipe do
    firewalld 'default' do
      action :delete
    end
  end
  it { is_expected.to remove_package('firewalld').with(options: ['--setopt=clean_requirements_on_remove=False']) }
end

describe 'firewall D-Bus backend dispatch' do
  platform 'ubuntu', '24.04'
  step_into :firewall, :firewall_backend_firewalld
  recipe do
    firewall 'default' do
      backend :firewalld
      action :install
    end
  end
  it { is_expected.to install_firewalld('default') }
  it 'does not add iptables-only established rules or restart an unchanged D-Bus service' do
    expect(chef_run.find_resources(:firewall_rule)).to be_empty
    expect(chef_run.run_context.delayed_actions).to be_empty
  end
end

describe 'generic firewalld rich-rule bridge' do
  platform 'ubuntu', '24.04'
  step_into :firewall_rule, :firewall_rule_firewalld
  recipe do
    firewall 'default' do
      backend :firewalld
      action :nothing
    end
    firewall_rule 'ports' do
      zone 'internal'
      port [22, 80..90]
      source '192.0.2.0/24'
      position(-5)
    end
  end
  it { is_expected.to add_firewalld_rich_rule('ports [22/tcp]').with(zone: 'internal', port: 22, source: '192.0.2.0/24', priority: -5, rule_action: :accept) }
  it { is_expected.to add_firewalld_rich_rule('ports [80..90/tcp]').with(zone: 'internal', port: '80-90') }

  context 'deleting a rule' do
    recipe do
      firewall 'default' do
        backend :firewalld
        action :nothing
      end
      firewall_rule 'ports' do
        zone 'internal'
        port 22
        action :delete
      end
    end
    it { is_expected.to remove_firewalld_rich_rule('ports').with(zone: 'internal', port: 22) }
  end

  context 'redirecting a port' do
    recipe do
      firewall 'default' do
        backend :firewalld
        action :nothing
      end
      firewall_rule 'redirect' do
        zone 'internal'
        source_port 8080
        redirect_port 80
        command :redirect
      end
    end
    it { is_expected.to add_firewalld_rich_rule('redirect').with(zone: 'internal', forward_port: 8080, to_port: 80, protocol: 'tcp') }
  end

  context 'unsupported backend properties' do
    recipe do
      firewall 'default' do
        backend :firewalld
        action :nothing
      end
      firewall_rule 'unsupported' do
        interface 'eth0'
      end
    end
    it 'fails rather than silently applying a broader rule' do
      expect { chef_run }.to raise_error(ArgumentError, /Unsupported firewalld rule properties: interface/)
    end
  end
end

describe 'firewalld rich rule rendering' do
  platform 'ubuntu', '24.04'
  step_into :firewalld_rich_rule
  let(:bus) { double('system bus') }
  let(:server) { double('server') }
  let(:config) { double('configuration') }
  let(:zone) { double('zone') }
  let(:runtime) { double('runtime', reload: nil) }

  before do
    stub_const('DBus', double('DBus', system_bus: bus, Error: Class.new(StandardError)))
    allow(bus).to receive(:[]).with('org.fedoraproject.FirewallD1').and_return(server)
    allow(server).to receive(:[]).with('/org/fedoraproject/FirewallD1/config').and_return({ 'org.fedoraproject.FirewallD1.config' => config })
    allow(server).to receive(:[]).with('/org/fedoraproject/FirewallD1').and_return({ 'org.fedoraproject.FirewallD1' => runtime })
    allow(config).to receive(:getZoneByName).with('internal').and_return('/zone')
    allow(server).to receive(:[]).with('/zone').and_return({ 'org.fedoraproject.FirewallD1.config.zone' => zone })
    allow(zone).to receive(:queryRichRule).and_return(false)
    allow(zone).to receive(:addRichRule)
    allow(runtime).to receive(:getDefaultZone).and_return('internal')
  end

  context 'the current default zone' do
    recipe do
      firewalld_rich_rule 'allow' do
        port 443
        protocol 'tcp'
        rule_action :accept
      end
    end
    it 'resolves the server default when no zone is supplied' do
      chef_run
      expect(config).to have_received(:getZoneByName).with('internal')
      expect(zone).to have_received(:addRichRule).with('rule port port="443" protocol="tcp" accept')
    end
  end

  context 'explicit false flags' do
    recipe do
      firewalld_rich_rule 'allow' do
        zone 'internal'
        port 443
        protocol 'tcp'
        log false
        audit false
        nflog false
        masquerade false
        rule_action :accept
      end
    end
    it 'does not enable optional logging, auditing or masquerading' do
      chef_run
      expect(zone).to have_received(:addRichRule).with('rule port port="443" protocol="tcp" accept')
    end
  end

  context 'local port forwarding' do
    recipe do
      firewalld_rich_rule 'forward' do
        zone 'internal'
        forward_port 8080
        to_port 80
        protocol 'tcp'
      end
    end
    it 'supplies the required family when there is no destination address' do
      chef_run
      expect(zone).to have_received(:addRichRule).with('rule family="ipv4" forward-port port="8080" protocol="tcp" to-port="80"')
    end
  end
end
