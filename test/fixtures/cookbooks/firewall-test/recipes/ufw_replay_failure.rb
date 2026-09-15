# frozen_string_literal: true

test_root = '/opt/firewall-ufw-replay-test'
failure_state = "#{test_root}/failure-injected"
success_state = "#{test_root}/replay-recovered"
wrapper_path = "#{test_root}/ufw"
rules_path = '/etc/default/ufw-chef.rules'

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

execute 'activate ufw before replay failure injection' do
  command '/usr/sbin/ufw --force enable'
  not_if "/usr/sbin/ufw status | grep -q '^Status: active'"
end

firewall_rule 'ufw replay failure probe' do
  raw 'allow 54321/tcp'
  notify_firewall false
end

ruby_block 'verify failed ufw replay remains retryable' do
  block do
    firewall_resource = Chef.run_context.resource_collection.find(firewall: 'default')
    persisted_before_failure = ::File.read(rules_path)
    original_path = ENV.fetch('PATH')
    ENV['PATH'] = "#{test_root}:#{original_path}"

    begin
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

      status = Mixlib::ShellOut.new('/usr/sbin/ufw', 'status').run_command
      status.error!
      raise 'UFW was not restored after the failed replay' unless status.stdout.match?(/^Status:\s+active/)

      firewall_resource.run_action(:restart)
    ensure
      ENV['PATH'] = original_path
    end

    unless ::File.read(rules_path).include?('ufw allow 54321/tcp')
      raise 'UFW rules marker was not committed after the successful retry'
    end

    ::File.write(success_state, "replay retried successfully\n")
  end
  not_if { ::File.exist?(success_state) }
end
