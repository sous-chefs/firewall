# frozen_string_literal: true

require 'spec_helper'

describe 'firewalld_rule' do
  step_into :firewalld_rule
  platform 'almalinux', '9'

  context 'with a simple port rule' do
    recipe do
      firewalld_rule 'ssh' do
        port 22
      end
    end

    it { is_expected.to create_firewalld_rule('ssh') }
    it { is_expected.to add_firewalld_rich_rule('ssh') }
  end

  context 'with an array port rule' do
    recipe do
      firewalld_rule 'ssh-alt' do
        port [2222, 2200]
      end
    end

    it { is_expected.to add_firewalld_rich_rule('ssh-alt [2222/tcp]') }
    it { is_expected.to add_firewalld_rich_rule('ssh-alt [2200/tcp]') }
  end

  context 'with a redirect rule' do
    recipe do
      firewalld_rule 'redirect' do
        command :redirect
        source_port 5555
        redirect_port 6666
      end
    end

    it { is_expected.to add_firewalld_rich_rule('redirect') }
  end
end
