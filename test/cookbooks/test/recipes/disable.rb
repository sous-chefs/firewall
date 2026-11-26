# frozen_string_literal: true

firewall 'default' do
  backend :iptables
  action :disable
end
