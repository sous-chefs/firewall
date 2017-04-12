source 'https://rubygems.org'

group :lint do
  gem 'foodcritic', '~> 10.3'
  gem 'rubocop', '~> 0.47'
  gem 'cookstyle', '~> 1.3'
end

group :unit do
  gem 'berkshelf', '~> 5.6'
  gem 'chefspec'
  gem 'chef-sugar'
  gem 'chef', '>= 13'
end

group :kitchen_windows do
  gem 'winrm-fs', '~> 1.0'
  gem 'winrm', '~> 2.0'
end

group :kitchen_common do
  gem 'test-kitchen', '~> 1.16'
end

group :kitchen_vagrant do
  gem 'kitchen-vagrant', '~> 1.1'
  gem 'vagrant-wrapper'
end

group :kitchen_cloud do
  gem 'kitchen-digitalocean'
  gem 'kitchen-ec2'
end

group :development do
  gem 'ruby_gntp'
  gem 'growl'
  gem 'rb-fsevent'
  gem 'guard'
  gem 'guard-kitchen'
  gem 'guard-foodcritic'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'rake', '~> 11.0'
  gem 'stove'
end
