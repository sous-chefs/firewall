# frozen_string_literal: true

require 'spec_helper'

describe 'ufw_rule' do
  step_into :ufw_rule
  platform 'ubuntu', '24.04'

  recipe do
    ufw 'default'

    ufw_rule 'ssh' do
      port 22
    end
  end

  it { is_expected.to create_ufw_rule('ssh') }
  it { is_expected.to run_ruby_block('queue ufw rebuild default ssh') }
end
