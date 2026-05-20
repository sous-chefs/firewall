# frozen_string_literal: true

require 'spec_helper'

describe 'nftables' do
  step_into :nftables
  platform 'debian', '12'

  recipe do
    nftables 'default'
  end

  it { is_expected.to install_package('nftables') }
end
