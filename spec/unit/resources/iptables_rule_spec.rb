# frozen_string_literal: true

require 'spec_helper'

describe 'iptables_rule' do
  step_into :iptables_rule
  platform 'ubuntu', '24.04'

  recipe do
    iptables 'default'

    iptables_rule 'ssh' do
      port 22
    end
  end

  it { is_expected.to create_iptables_rule('ssh') }
  it { is_expected.to run_ruby_block('queue iptables rebuild default ssh') }
end
