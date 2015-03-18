require_relative 'spec_helper'

if %w(debian ubuntu).include?(os[:family])
  require_relative 'debian'
elsif os[:family] == 'redhat'
  require_relative 'redhat'
end
