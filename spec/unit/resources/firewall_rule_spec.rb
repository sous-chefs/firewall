# frozen_string_literal: true

require 'spec_helper'

describe 'firewall_rule' do
  step_into :firewall_rule

  context 'with a UFW backend' do
    platform 'ubuntu', '24.04'

    recipe do
      firewall 'default' do
        backend :ufw
      end

      firewall_rule 'ssh' do
        port 22
      end
    end

    it { is_expected.to create_ufw_rule('ssh') }
  end

  context 'with firewalld backend' do
    platform 'almalinux', '9'

    recipe do
      firewall 'default' do
        backend :firewalld
      end

      firewall_rule 'ssh' do
        port 22
      end
    end

    it { is_expected.to create_firewalld_rule('ssh') }
  end

  context 'with nftables backend' do
    platform 'debian', '12'

    recipe do
      firewall 'default' do
        backend :nftables
      end

      firewall_rule 'ssh' do
        port 22
      end
    end

    it { is_expected.to create_nftables_rule('ssh') }
  end

  context 'with iptables backend' do
    platform 'ubuntu', '24.04'

    recipe do
      firewall 'default' do
        backend :iptables
      end

      firewall_rule 'ssh' do
        port 22
      end
    end

    it { is_expected.to create_iptables_rule('ssh') }
  end
end
