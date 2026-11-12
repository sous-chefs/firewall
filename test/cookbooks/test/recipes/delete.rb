# frozen_string_literal: true

firewall 'default' do
  backend node.dig('firewall_test', 'backend').to_sym if node.dig('firewall_test', 'backend')
  action :delete
end
