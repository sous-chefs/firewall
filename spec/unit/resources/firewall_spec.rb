# frozen_string_literal: true

require 'spec_helper'

describe 'firewall' do
  step_into :firewall, :nftables

  context 'on Ubuntu with UFW' do
    platform 'ubuntu', '24.04'

    recipe do
      firewall 'default' do
        backend :ufw
        allow_ssh true
        allow_mosh true
      end
    end

    it { is_expected.to install_package('ufw') }
    it { is_expected.to create_template('/etc/default/ufw') }
    it { is_expected.to enable_service('ufw') }
  end

  context 'on Debian with the platform default nftables backend' do
    platform 'debian', '12'

    recipe do
      firewall 'default'
    end

    it { is_expected.to install_nftables('default') }
  end

  context 'when rebuilding nftables default rules' do
    platform 'debian', '12'

    recipe do
      firewall 'default' do
        backend :nftables
        action :restart
        allow_loopback true
        allow_icmp true
        allow_ssh true
        allow_mosh true
      end
    end

    it { is_expected.to create_file('/etc/nftables.conf').with_content(/tcp dport 22 accept comment "allow world to ssh"/) }
    it { is_expected.to create_file('/etc/nftables.conf').with_content(/udp dport 60000-61000 accept comment "allow world to mosh"/) }
    it { is_expected.to create_file('/etc/nftables.conf').with_content(/iif lo accept comment "allow loopback"/) }
    it { is_expected.to create_file('/etc/nftables.conf').with_content(/icmp type echo-request accept comment "allow icmp"/) }
    it { is_expected.to enable_service('nftables') }
  end

  context 'on Ubuntu with iptables' do
    platform 'ubuntu', '24.04'

    recipe do
      firewall 'default' do
        backend :iptables
        allow_loopback true
        allow_icmp true
      end
    end

    it { is_expected.to install_package('iptables-persistent') }
    it { is_expected.to enable_service('netfilter-persistent') }
  end

  context 'on AlmaLinux with firewalld' do
    platform 'almalinux', '9'

    recipe do
      firewall 'default' do
        backend :firewalld
      end
    end

    it { is_expected.to install_firewalld('default') }
  end

  context 'when applying default firewalld rules' do
    platform 'almalinux', '9'

    recipe do
      firewall 'default' do
        backend :firewalld
        allow_ssh true
        allow_mosh true
      end
    end

    it { is_expected.to add_firewalld_rich_rule('allow world to ssh') }
    it { is_expected.to add_firewalld_rich_rule('allow world to mosh') }
  end
end
