# Encoding: utf-8
require 'serverspec'
require_relative 'helpers'

if (/cygwin|mswin|mingw|bccwin|wince|emx/ =~ RUBY_PLATFORM).nil?
  set :backend, :exec
  set :path, '/sbin:/usr/local/sbin:/bin:/usr/bin:$PATH'
else
  set :backend, :cmd
  set :os, family: 'windows'
end

RSpec::Matchers.define :count_occurences do |expected_string, expected_count|
  match do |actual_string|
    actual_string.to_s.scan(expected_string).count == expected_count
  end

  description do
    "#{expected_string} should occur #{expected_count} times"
  end

  failure_message do |actual|
    "expected that '#{expected_string}' would occur in the following string #{expected_count} times:\n#{actual}\n"
  end
end
