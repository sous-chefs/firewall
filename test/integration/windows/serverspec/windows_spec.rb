# these tests only for windows
require 'spec_helper'

expected_rules = [
  %r{firewall add rule name="Outgoing_Rule_0" description="Outgoing_Rule_0" dir=out service=any protocol=tcp localip=any localport=any interfacetype=any remoteip=any remoteport=8080 action=allow},
  %r{firewall add rule name="Incoming_Rule_1" description="Incoming_Rule_1" dir=in service=any protocol=tcp localip=any localport=5985 interfacetype=any remoteip=any remoteport=any action=allow},
  %r{firewall add rule name="Incoming_Rule_2" description="Incoming_Rule_2" dir=in service=any protocol=udp localip=any localport=5985 interfacetype=any remoteip=any remoteport=any action=allow},
  %r{firewall add rule name="Incoming_Rule_3" description="Incoming_Rule_3" dir=in service=any protocol=tcp localip=any localport=5986 interfacetype=any remoteip=any remoteport=any action=allow},
  %r{firewall add rule name="Incomingt_Rule_4" description="Incomingt_Rule_4" dir=in service=any protocol=tcp localip=any localport=3389 interfacetype=any remoteip=any remoteport=any action=allow},
  %r{firewall add rule name="Incomingt_Rule_5" description="Incomingt_Rule_5" dir=in service=any protocol=tcp localip=any localport=80 interfacetype=any remoteip=any remoteport=any action=allow},
  %r{firewall add rule name="allow world to winrm" description="allow world to winrm" dir=in service=any protocol=tcp localip=any localport=5989 interfacetype=any remoteip=any remoteport=any action=allow}
]

describe file("#{ENV['HOME']}/windows-chef.rules"), if: windows? do
  expected_rules.each do |r|
    its(:content) { should match(r) }
  end
end

describe command('netsh advfirewall firewall show rule name=all'), if: windows? do
  its(:stdout) { should count_occurences('Rule Name:', 7) }
end
