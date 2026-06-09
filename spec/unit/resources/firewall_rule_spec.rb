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

  context 'with nftables-specific rule options through the firewall_rule facade' do
    platform 'debian', '12'

    recipe do
      firewall 'default' do
        backend :nftables
      end

      firewall_rule 'logged ssh' do
        command [:log, :counter, :accept]
        log_prefix 'TEST_PREFIX:'
        log_group 0
        port 22
      end
    end

    it do
      expect(chef_run).to create_nftables_rule('logged ssh')
        .with(command: [:log, :counter, :accept],
              dport: 22,
              log_prefix: 'TEST_PREFIX:',
              log_group: 0)
    end
  end

  context 'with facade properties mapped to native nftables properties' do
    platform 'debian', '12'

    recipe do
      firewall 'default' do
        backend :nftables
      end

      firewall_rule 'mapped aliases' do
        source_port 1024
        port 22
        dest_port 8443
        dest_interface 'eth1'
      end
    end

    it do
      expect(chef_run).to create_nftables_rule('mapped aliases')
        .with(sport: 1024,
              dport: 8443,
              outerface: 'eth1')
    end
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
