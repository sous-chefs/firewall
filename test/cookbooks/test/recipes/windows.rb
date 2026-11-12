# frozen_string_literal: true

%w(duplicate0 duplicate1).each do |rule_name|
  [1111, [5431, 5432]].each do |rule_ports|
    firewall_rule rule_name do
      description 'same comment'
      port rule_ports
    end
  end
end
