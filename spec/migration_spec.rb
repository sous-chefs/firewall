# frozen_string_literal: true

require 'spec_helper'

describe 'firewall custom resources' do
  platform 'ubuntu', '24.04'
  step_into :firewall, :firewall_rule

  recipe do
    firewall 'default' do
      backend :ufw
      action :nothing
    end
    firewall_rule 'https' do
      port 443
    end
  end

  it 'registers rules without claiming a system change' do
    expect(chef_run.firewall_rule('https').updated_by_last_action?).to be(false)
  end
end
