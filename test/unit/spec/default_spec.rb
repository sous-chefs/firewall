require_relative 'spec_helper'

describe 'firewall::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'installs ufw package' do
    expect(chef_run).to install_package('ufw')
  end
end

describe 'firewall-test::default' do
  let(:chef_run) { ChefSpec::SoloRunner.converge(described_recipe) }

  it 'enables the firewall' do
    expect(chef_run).to enable_firewall('ufw')
  end
end
