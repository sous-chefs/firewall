# frozen_string_literal: true

require 'spec_helper'

{
  firewalld_helper: ['Helper', ['', 'managed', 'managed', 'ipv4', 'nf_conntrack_ftp', []]],
  firewalld_icmptype: ['IcmpType', ['', 'managed', 'managed', ['ipv4']]],
  firewalld_ipset: ['IPSet', ['', 'managed', 'managed', 'hash:ip', {}, []]],
  firewalld_policy: ['Policy', {}],
  firewalld_service: ['Service', {}],
  firewalld_zone: ['Zone', {}],
}.each do |resource_name, (type, settings)|
  describe "#{resource_name} deletion" do
    platform 'ubuntu', '24.04'
    step_into resource_name
    let(:interface) { double('firewalld D-Bus interface') }
    let(:names) { [] }

    before do
      stub_const('DBus', double('DBus', system_bus: interface))
      allow(interface).to receive(:[]).and_return(interface)
      allow(interface).to receive("get#{type}Names").and_return(names)
      allow(interface).to receive("get#{type}ByName").with('managed').and_return('/managed')
      allow(interface).to receive(:getSettings).and_return(settings)
      allow(interface).to receive(:getSettings2).and_return(settings)
      allow(interface).to receive(:remove)
      allow(interface).to receive(:reload)
    end

    recipe do
      public_send(resource_name, 'managed') { action :delete }
    end

    it 'does not remove or reload an absent object' do
      chef_run
      expect(interface).not_to have_received(:remove)
      expect(interface).not_to have_received(:reload)
    end

    context 'when the object exists' do
      let(:names) { ['managed'] }
      it 'removes the object and reloads the permanent configuration' do
        chef_run
        expect(interface).to have_received(:remove).once
        expect(interface).to have_received(:reload).once
      end
    end
  end
end

describe 'firewalld_zone boolean updates' do
  platform 'ubuntu', '24.04'
  step_into :firewalld_zone
  let(:interface) { double('firewalld D-Bus interface') }
  before do
    stub_const('DBus', double('DBus', system_bus: interface))
    allow(interface).to receive(:[]).and_return(interface)
    allow(interface).to receive(:getZoneNames).and_return(['managed'])
    allow(interface).to receive(:getZoneByName).and_return('/managed')
    allow(interface).to receive(:getSettings2).and_return('forward' => true, 'masquerade' => true, 'description' => 'managed')
    allow(interface).to receive(:update2)
    allow(interface).to receive(:reload)
  end
  recipe do
    firewalld_zone 'managed' do
      forward false
      masquerade false
    end
  end
  it 'sends explicit false values to the server' do
    chef_run
    expect(interface).to have_received(:update2).with('forward' => false)
    expect(interface).to have_received(:update2).with('masquerade' => false)
  end

  context 'combined priority' do
    recipe do
      firewalld_zone 'managed' do
        priority(-10)
      end
    end
    it 'sets ingress and egress priorities without sending the shorthand to D-Bus' do
      chef_run
      expect(interface).to have_received(:update2).with('ingress_priority' => -10)
      expect(interface).to have_received(:update2).with('egress_priority' => -10)
      expect(interface).not_to have_received(:update2).with('priority' => -10)
    end
  end

  context 'a new zone' do
    before do
      allow(interface).to receive(:getZoneNames).and_return([])
      allow(interface).to receive(:addZone2)
    end
    it 'preserves the existing safe forwarding default when creating the zone' do
      chef_run
      expect(interface).to have_received(:addZone2).with('managed', { 'forward' => false })
    end
  end
end

describe 'firewalld_config partial updates' do
  platform 'ubuntu', '24.04'
  step_into :firewalld_config
  let(:interface) { double('firewalld D-Bus interface') }
  before do
    stub_const('DBus', double('DBus', system_bus: interface))
    allow(interface).to receive(:[]).and_return(interface)
    allow(interface).to receive(:getDefaultZone).and_return('public')
    allow(interface).to receive(:getLogDenied).and_return('all')
    allow(interface).to receive(:setDefaultZone)
    allow(interface).to receive(:setLogDenied)
  end
  recipe do
    firewalld_config 'default' do
      default_zone 'drop'
    end
  end
  it 'updates the requested zone and preserves unspecified logging' do
    chef_run
    expect(interface).to have_received(:setDefaultZone).with('drop')
    expect(interface).not_to have_received(:setLogDenied)
  end
end
