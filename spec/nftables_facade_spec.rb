# frozen_string_literal: true

require 'spec_helper'

describe 'the opt-in nftables firewall backend' do
  platform 'debian', '12'
  step_into :firewall, :firewall_rule, :firewall_backend_nftables, :nftables, :ruby_block

  before { stub_command('systemctl is-active --quiet nftables.service').and_return(false) }

  context 'without an explicit backend' do
    recipe { firewall 'default' }

    it { is_expected.to install_firewall_backend_ufw('default') }
    it { is_expected.not_to install_package('nftables') }
  end

  context 'with explicit nftables rules' do
    recipe do
      managed_firewall = firewall 'example' do
        backend :nftables
        allow_ssh true
        allow_loopback true
      end

      firewall_rule 'logged https' do
        firewall_name 'example'
        command [:log, :counter, :accept]
        log_prefix 'example:'
        log_group 0
        protocol 6
        source_port 1024..65000
        port 443
        dest_port 8443
        dest_interface 'eth0'
        notify_firewall false
      end

      firewall_rule 'TCP only' do
        firewall_name 'example'
        protocol :tcp
        command :deny
      end

      firewall_rule 'IPv6 only' do
        firewall_name 'example'
        protocol :ipv6
      end

      firewall_rule 'IPv6 outbound' do
        firewall_name 'example'
        protocol :ipv6
        direction :post
        command :masquerade
      end

      firewall_rule 'any family' do
        firewall_name 'example'
        protocol :none
      end

      firewall_rule 'all IPv4 sources' do
        firewall_name 'example'
        protocol :none
        source '0.0.0.0/0'
      end

      firewall_rule 'one IPv6 source' do
        firewall_name 'example'
        protocol :none
        source '::/128'
      end

      firewall_rule 'deleted connection' do
        firewall_name 'example'
        port 8888
        action :delete
      end

      ruby_block 'reconcile the test firewall' do
        block { managed_firewall.run_action(:restart) }
      end
    end

    it { is_expected.to install_package('nftables') }
    it 'reconciles the complete named ruleset' do
      run = chef_run
      expect(run).to enable_systemd_unit('nftables.service')
      expect(run).to start_systemd_unit('nftables.service')
      expect(run).to render_file('/etc/nftables.conf').with_content(/policy drop/)
      expect(run).to render_file('/etc/nftables.conf').with_content(/tcp dport 22 accept/)
      expect(run).to render_file('/etc/nftables.conf').with_content(/iif lo accept/)
      expect(run).to render_file('/etc/nftables.conf').with_content(/oif eth0 tcp sport 1024-65000 tcp dport 8443 log prefix "example:" group 0 counter accept/)
      expect(run).to render_file('/etc/nftables.conf').with_content(/meta l4proto 6 drop comment "TCP only"/)
      expect(run).to render_file('/etc/nftables.conf').with_content(/add rule inet filter INPUT meta nfproto ipv6 accept comment "IPv6 only"/)
      expect(run).to render_file('/etc/nftables.conf').with_content(/add rule ip6 nat POSTROUTING masquerade comment "IPv6 outbound"/)
      expect(run).to render_file('/etc/nftables.conf').with_content(/add rule inet filter INPUT accept comment "any family"/)
      expect(run).to render_file('/etc/nftables.conf').with_content('ip saddr 0.0.0.0/0 accept comment "all IPv4 sources"')
      expect(run).to render_file('/etc/nftables.conf').with_content('ip6 saddr ::/128 accept comment "one IPv6 source"')
      expect(run).not_to render_file('/etc/nftables.conf').with_content(/8888/)
    end
  end

  context 'with an IPv4 address on an IPv6 rule' do
    recipe do
      managed_firewall = firewall 'default' do
        backend :nftables
      end
      firewall_rule 'invalid' do
        protocol :ipv6
        source '192.0.2.10'
      end
      ruby_block 'reconcile the test firewall' do
        block { managed_firewall.run_action(:restart) }
      end
    end

    it 'rejects the contradictory address family' do
      expect { chef_run }.to raise_error(ArgumentError, /protocol :ipv6 cannot match an IPv4 address/)
    end
  end

  context 'with IPv6 management disabled' do
    recipe do
      managed_firewall = firewall 'default' do
        backend :nftables
        ipv6_enabled false
        allow_ssh true
      end
      ruby_block 'reconcile the test firewall' do
        block { managed_firewall.run_action(:restart) }
      end
    end

    it 'limits filter rules and policies to IPv4' do
      expect(chef_run).to render_file('/etc/nftables.conf').with_content('add table ip filter')
      expect(chef_run).to render_file('/etc/nftables.conf').with_content(/add chain ip filter INPUT .*policy drop/)
      expect(chef_run).to render_file('/etc/nftables.conf').with_content('add rule ip filter INPUT tcp dport 22 accept')
      expect(chef_run).not_to render_file('/etc/nftables.conf').with_content(/add table (inet|ip6)/)
    end
  end

  context 'with an IPv6 rule while IPv6 management is disabled' do
    recipe do
      managed_firewall = firewall 'default' do
        backend :nftables
        ipv6_enabled false
      end
      firewall_rule 'invalid' do
        protocol :ipv6
      end
      ruby_block 'reconcile the test firewall' do
        block { managed_firewall.run_action(:restart) }
      end
    end

    it 'rejects the rule before activating an IPv4-only configuration' do
      expect { chef_run }.to raise_error(ArgumentError, /IPv6 rules require ipv6_enabled/)
    end
  end

  context 'with a port match on an unrelated protocol' do
    recipe do
      managed_firewall = firewall 'default' do
        backend :nftables
      end
      firewall_rule 'invalid' do
        protocol 112
        port 80
      end
      ruby_block 'reconcile the test firewall' do
        block { managed_firewall.run_action(:restart) }
      end
    end

    it 'rejects the rule instead of dropping its port restriction' do
      expect { chef_run }.to raise_error(ArgumentError, /Ports require TCP or UDP/)
    end
  end

  context 'with a property for a different backend' do
    recipe do
      managed_firewall = firewall 'default' do
        backend :nftables
      end
      firewall_rule 'invalid' do
        zone 'public'
      end
      ruby_block 'reconcile the test firewall' do
        block { managed_firewall.run_action(:restart) }
      end
    end

    it 'rejects the unsupported match' do
      expect { chef_run }.to raise_error(ArgumentError, /Unsupported nftables rule properties: zone/)
    end
  end

  context 'with nftables commands on a different backend' do
    recipe do
      firewall 'default'
      firewall_rule 'invalid' do
        command [:log, :counter, :accept]
      end
    end

    it 'requires the explicit nftables backend' do
      expect { chef_run }.to raise_error(ArgumentError, /unsupported on ufw/i)
    end
  end
end
