require_relative 'spec_helper'

describe 'firewall::firewalld' do
  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04').converge(described_recipe) }

  it 'enables the firewall' do
    expect(chef_run).to install_firewall('firewalld')
  end
end

describe 'firewall-test::firewalld' do
  let(:chef_run) { ChefSpec::SoloRunner.new(platform: 'ubuntu', version: '14.04', step_into: ['firewall_rule']).converge(described_recipe) }

  it 'enables the firewall' do
    expect(chef_run).to restart_firewall('firewalld')
  end

  it 'creates some rules' do
    %w(ssh22 ssh2222 duplicate0 temp1 ipv6-source).each do |r|
      expect(chef_run).to create_firewall_rule(r)
    end
  end
end
