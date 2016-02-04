require 'bundler/setup'
require 'rspec/core/rake_task'
require 'rubocop/rake_task'
require 'foodcritic'
require 'kitchen'

# Style tests. Rubocop and Foodcritic
namespace :style do
  desc 'Run Ruby style checks'
  RuboCop::RakeTask.new(:ruby)

  desc 'Run Chef style checks'
  FoodCritic::Rake::LintTask.new(:chef) do |t|
    t.options = { search_gems: true,
                  fail_tags: ['correctness'],
                  chef_version: '12.4.1',
                  tags: %w(~FC001 ~FC019),
                }
  end
end

desc 'Run all style checks'
task style: ['style:chef', 'style:ruby']

# Rspec and ChefSpec
desc 'Run ChefSpec unit tests'
RSpec::Core::RakeTask.new(:spec) do |t, _args|
  t.rspec_opts = 'test/unit'
end

# Integration tests. Kitchen.ci
namespace :integration do
  desc 'Run Test Kitchen with Vagrant'
  task :vagrant do
    Kitchen.logger = Kitchen.default_file_logger
    Kitchen::Config.new.instances.each do |instance|
      instance.test(:always)
    end
  end

  desc 'Run Test Kitchen with cloud plugins'
  task :cloud do
    if ENV['CI_DOES_NOT_WORK'] == 'true'
      Kitchen.logger = Kitchen.default_file_logger
      @loader = Kitchen::Loader::YAML.new(local_config: '.kitchen.cloud.yml')
      config = Kitchen::Config.new(loader: @loader)
      concurrency = config.instances.size
      queue = Queue.new
      config.instances.each { |i| queue << i }
      concurrency.times { queue << nil }
      threads = []
      concurrency.times do
        threads << Thread.new do
          while instance = queue.pop
            instance.test(:always)
          end
        end
      end
      threads.map(&:join)
    end
  end
end

desc 'Run all tests on CI Platform'
task ci: %w(style spec) # 'integration:cloud'

# Default
task default: %w(style spec) # 'integration:vagrant'
