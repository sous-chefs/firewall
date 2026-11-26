# frozen_string_literal: true

firewall 'default' do
  backend :iptables
  allow_ssh true
end
