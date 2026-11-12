# frozen_string_literal: true

case input('removal_type')
when 'custom_policy'
  %w(iptables ip6tables).each do |family|
    describe command("#{family} -t mangle -S FORWARD") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match(/-P FORWARD DROP/) }
    end
  end
when 'disable', 'nat_remove'
  %w(iptables ip6tables).each do |family|
    describe command("#{family} -t nat -S") do
      its('exit_status') { should eq 0 }
      its('stdout') { should_not match(/--dports 5555/) }
    end
    next unless input('removal_type') == 'disable'
    describe command("#{family} -t mangle -S FORWARD") do
      its('exit_status') { should eq 0 }
      its('stdout') { should match(/-P FORWARD ACCEPT/) }
    end
  end
when 'dbus_delete'
  {
    'policies' => %w(ptest pminimal),
    'zones' => %w(ztest ztest2 rich-rules zpriority1 zpriority2),
    'services' => %w(ssh2 minimal-service),
    'ipsets' => %w(example-ips single-ip),
    'icmptypes' => %w(rick-rolled minimal-icmptype),
    'helpers' => %w(example-helper minimal-helper),
  }.each do |type, names|
    describe command("firewall-cmd --permanent --get-#{type}") do
      its('exit_status') { should eq 0 }
      names.each { |name| its('stdout') { should_not match(/\b#{Regexp.escape(name)}\b/) } }
    end
  end
when 'nftables_delete'
  describe package('nftables') do
    it { should_not be_installed }
  end
  describe file(os.debian? ? '/etc/nftables.conf' : '/etc/sysconfig/nftables.conf') do
    it { should_not exist }
  end
else
  backend = input('removal_backend')
  backend = os.debian? ? 'ufw' : 'firewalld' if backend == 'auto' || backend == 'default'
  if backend == 'ufw'
    describe package('ufw') do
      it { should_not be_installed }
    end
    describe file('/etc/default/ufw-chef.rules') do
      it { should_not exist }
    end
  elsif backend == 'firewalld' || backend == 'firewalld-simple'
    describe package('firewalld') do
      it { should_not be_installed }
    end
  elsif backend == 'iptables'
    describe package(os.debian? ? 'iptables-persistent' : 'iptables-services') do
      it { should_not be_installed }
    end
    %w(iptables ip6tables).each do |family|
      path = if os.debian?
               "/etc/iptables/rules.#{family == 'ip6tables' ? 'v6' : 'v4'}"
             else
               "/etc/sysconfig/#{family}"
             end
      describe file(path) do
        it { should_not exist }
      end
    end
  end
end
