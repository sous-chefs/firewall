# frozen_string_literal: true

%w(duplicate0 duplicate1).each do |rule_name|
  [1111, [5431, 5432]].each do |rule_ports|
    firewall_rule rule_name do
      description 'same comment'
      port rule_ports
    end
  end
end

{ 'outbound-https' => 443, 'outbound-range' => 50000..50002, 'outbound-array' => [443, 8443] }.each do |rule_name, ports|
  firewall_rule rule_name do
    direction :out
    port ports
  end
end

{ 'numeric-tcp' => [6, 4443], 'numeric-udp' => [17, 5353] }.each do |rule_name, (number, ports)|
  firewall_rule rule_name do
    protocol number
    port ports
  end
end
