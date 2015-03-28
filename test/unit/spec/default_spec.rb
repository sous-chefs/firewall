require_relative 'spec_helper'

describe 'firewall::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'enables the firewall' do
    expect(chef_run).to enable_firewall('default')
  end
end

describe 'firewall-test::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'enables the firewall' do
    expect(chef_run).to enable_firewall('default')
  end

  it 'creates some rules' do
    %w(ssh22 ssh2222 addremove duplicate0).each do |r|
      expect(chef_run).to allow_firewall_rule(r)
    end

    expect(chef_run).to deny_firewall_rule('temp1')
  end
end
