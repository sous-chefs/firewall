# frozen_string_literal: true

require 'spec_helper'

describe 'firewall_rule' do
  step_into :firewall_rule

  context 'with a non-firewalld backend' do
    platform 'ubuntu', '24.04'

    recipe do
      firewall 'default' do
        solution :ufw
      end

      firewall_rule 'ssh' do
        port 22
      end
    end

    it { is_expected.to create_firewall_rule('ssh') }
  end

  context 'with firewalld backend' do
    platform 'almalinux', '9'

    recipe do
      firewall 'default' do
        solution :firewalld
      end

      firewall_rule 'ssh' do
        port 22
      end
    end

    it { is_expected.to add_firewalld_rich_rule('ssh') }
  end
end
