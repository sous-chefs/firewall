# frozen_string_literal: true

# The installed D-Bus library must be loaded in each Chef process.
require 'dbus'
{
  firewalld_policy: %w(ptest pminimal),
  firewalld_zone: %w(ztest ztest2 rich-rules zpriority1 zpriority2),
  firewalld_service: %w(ssh2 minimal-service),
  firewalld_ipset: %w(example-ips single-ip),
  firewalld_icmptype: %w(rick-rolled minimal-icmptype),
  firewalld_helper: %w(example-helper minimal-helper),
}.each do |type, names|
  names.each { |object_name| public_send(type, object_name) { action :delete } }
end
