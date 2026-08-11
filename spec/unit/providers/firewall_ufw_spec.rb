# frozen_string_literal: true

require 'spec_helper'
require_relative '../../../libraries/helpers'
require_relative '../../../libraries/helpers_ufw'
require_relative '../../../libraries/resource_firewall'
require_relative '../../../libraries/provider_firewall_ufw'

describe Chef::Provider::FirewallUfw do
  let(:node) { Chef::Node.new }
  let(:events) { Chef::EventDispatch::Dispatcher.new }
  let(:run_context) { Chef::RunContext.new(node, {}, events) }
  let(:resource) do
    Chef::Resource::Firewall.new('default', run_context).tap do |firewall|
      firewall.rules('ufw' => { 'ufw allow 22/tcp' => 50 })
    end
  end
  let(:rules_filename) { '/etc/default/ufw-chef.rules' }
  let(:persisted_rules) { { content: "# previous rules\n", updated: false } }
  let(:firewall_state) { { active: true } }
  let(:rule_attempts) { [] }
  let(:rules_file) { instance_double(Chef::Resource::File) }

  before do
    pending_content = nil

    allow(Chef).to receive(:run_context).and_return(run_context)
    allow(::File).to receive(:exist?).and_call_original
    allow(::File).to receive(:exist?).with(rules_filename).and_return(true)
    allow(::File).to receive(:read).and_call_original
    allow(::File).to receive(:read).with(rules_filename).and_wrap_original do |_method, *_args|
      persisted_rules[:content]
    end

    allow(rules_file).to receive(:content) { |content| pending_content = content }
    allow(rules_file).to receive(:run_action).with(:create) do
      persisted_rules[:updated] = persisted_rules[:content] != pending_content
      persisted_rules[:content] = pending_content
    end
    allow(rules_file).to receive(:updated_by_last_action?) { persisted_rules[:updated] }
  end

  def build_provider
    described_class.new(resource, run_context).tap do |provider|
      allow(provider).to receive(:lookup_or_create_rulesfile).and_return(rules_file)
      allow(provider).to receive(:ufw_active?) { firewall_state[:active] }
      allow(provider).to receive(:ufw_reset!) { firewall_state[:active] = false }
      allow(provider).to receive(:ufw_logging!)
      allow(provider).to receive(:ufw_enable!) { firewall_state[:active] = true }
      allow(provider).to receive(:ufw_rule!) do |command|
        rule_attempts << command
        raise Mixlib::ShellOut::ShellCommandFailed, 'injected replay failure' if rule_attempts.one?
      end
    end
  end

  it 'does not commit desired rules and restores an active firewall after replay fails' do
    expect { build_provider.run_action(:restart) }
      .to raise_error(Mixlib::ShellOut::ShellCommandFailed, 'injected replay failure')

    aggregate_failures do
      expect(persisted_rules[:content]).to eq("# previous rules\n")
      expect(firewall_state[:active]).to be(true)
    end
  end

  it 'retries on the next converge, commits after success, and is then idempotent' do
    expect { build_provider.run_action(:restart) }
      .to raise_error(Mixlib::ShellOut::ShellCommandFailed, 'injected replay failure')

    expect { build_provider.run_action(:restart) }.not_to raise_error

    expect(rule_attempts).to eq(['ufw allow 22/tcp', 'ufw allow 22/tcp'])
    expect(persisted_rules[:content]).to eq("# position 50\nufw allow 22/tcp\n")
    expect(firewall_state[:active]).to be(true)

    expect { build_provider.run_action(:restart) }.not_to raise_error
    expect(rule_attempts).to eq(['ufw allow 22/tcp', 'ufw allow 22/tcp'])
    expect(rules_file).to have_received(:run_action).with(:create).once
  end
end
