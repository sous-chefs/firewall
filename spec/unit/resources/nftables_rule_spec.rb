# frozen_string_literal: true

require 'spec_helper'

describe 'nftables_rule' do
  step_into :nftables_rule
  platform 'debian', '12'

  recipe do
    nftables 'default'

    nftables_rule 'ssh' do
      dport 22
    end
  end

  it { is_expected.to create_nftables_rule('ssh') }
end
