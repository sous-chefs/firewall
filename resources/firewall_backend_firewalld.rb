# frozen_string_literal: true

provides :firewall_backend_firewalld
unified_mode true
use '_partial/_firewall'

%i(install reload restart disable delete).each do |operation|
  action operation do
    firewalld new_resource.name do
      package_options new_resource.package_options if new_resource.package_options
      action operation
    end
  end
end
