# frozen_string_literal: true

test_root = '/opt/firewall-ufw-replay-test'
failure_state = "#{test_root}/failure-injected"
success_state = "#{test_root}/replay-recovered"
wrapper_path = "#{test_root}/ufw"
rules_path = '/etc/default/ufw-chef.rules'
firewall_resource = Chef.run_context.resource_collection.find(firewall: 'default')
previous_defaults = firewall_resource.ufw_defaults
new_defaults = previous_defaults.merge(policy: previous_defaults.fetch(:policy).merge(output: 'REJECT'))
firewall_resource.ufw_defaults(new_defaults) if ::File.exist?(success_state)

directory test_root do
  recursive true
end

file wrapper_path do
  mode '0755'
  content <<~SH
    #!/bin/sh
    set -eu

    if [ "$*" = "allow 54321/tcp" ] && [ ! -e "#{failure_state}" ]; then
      touch "#{failure_state}"
      echo "injected UFW replay failure" >&2
      exit 1
    fi

    exec /usr/sbin/ufw "$@"
  SH
end

ruby_block 'apply the baseline UFW rules before injecting a replay failure' do
  block { Chef.run_context.resource_collection.find(firewall: 'default').run_action(:restart) }
  not_if { ::File.exist?(success_state) }
end

firewall_rule 'ufw replay failure probe' do
  raw 'allow 54321/tcp'
  notify_firewall false
end

ruby_block 'verify failed ufw replay remains retryable' do
  block do
    persisted_before_failure = ::File.read(rules_path)
    user_rules = '/etc/ufw/user.rules'
    installed_before_failure = ::File.binread(user_rules)
    defaults_path = '/etc/default/ufw'
    defaults_before_failure = ::File.binread(defaults_path)
    firewall_resource.ufw_defaults(new_defaults)
    original_path = ENV.fetch('PATH')
    ENV['PATH'] = "#{test_root}:#{original_path}"

    begin
      # UFW names reset backups with second-level timestamps.
      sleep 1
      replay_failure = nil
      begin
        firewall_resource.run_action(:restart)
      rescue Mixlib::ShellOut::ShellCommandFailed => e
        replay_failure = e
      end

      unless replay_failure&.message&.include?('injected UFW replay failure')
        raise 'UFW replay did not raise the injected failure'
      end

      unless ::File.read(rules_path) == persisted_before_failure
        raise 'UFW rules marker changed despite a failed replay'
      end

      raise 'UFW did not restore its prior rules file' unless ::File.binread(user_rules) == installed_before_failure
      raise 'UFW did not restore its prior defaults' unless ::File.binread(defaults_path) == defaults_before_failure

      status = Mixlib::ShellOut.new('/usr/sbin/ufw', 'status', 'verbose').run_command
      status.error!
      raise 'UFW was not restored after the failed replay' unless status.stdout.match?(/^Status:\s+active/)
      raise 'The earlier SSH rule was not reloaded' unless status.stdout.match?(%r{^22/tcp\s+ALLOW})
      raise 'The previous outgoing policy was not restored' unless status.stdout.include?('allow (outgoing)')

      sleep 1
      firewall_resource.run_action(:restart)
    ensure
      ENV['PATH'] = original_path
    end

    unless ::File.read(rules_path).include?('ufw allow 54321/tcp')
      raise 'UFW rules marker was not committed after the successful retry'
    end
    raise 'The new defaults were not applied on retry' unless ::File.read(defaults_path).include?('DEFAULT_OUTPUT_POLICY="REJECT"')

    ::File.write(success_state, "replay retried successfully\n")
  end
  not_if { ::File.exist?(success_state) }
end
