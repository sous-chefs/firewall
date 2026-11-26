# frozen_string_literal: true

provides :firewall_backend_ufw
unified_mode true
use '_partial/_firewall'

action :install do
  package 'ufw' do
    options new_resource.package_options if new_resource.package_options
  end
  file ufw_rules_filename do
    content '# created by chef to allow service to start'
    action :create_if_missing
  end
end

action :restart do
  desired = (new_resource.rules['ufw'] || {}).dup
  new_resource.rule_resources.each { |rule| desired[build_rule(rule)] = rule.position }
  contents = "# logging=#{new_resource.log_level} ipv6=#{new_resource.ipv6_enabled} defaults=#{new_resource.ufw_defaults.inspect}\n#{build_rule_file(desired)}"
  defaults_path = '/etc/default/ufw'
  defaults = new_resource.ufw_defaults.merge(ipv6: new_resource.ipv6_enabled ? 'yes' : 'no')
  cookbook = run_context.cookbook_collection['firewall']
  source = cookbook.preferred_filename_on_disk_location(node, :templates, 'ufw/default.erb')
  defaults_content = Chef::Mixin::Template::TemplateContext.new(defaults: defaults, node: node).render_template(source)

  defaults_file = file 'desired UFW defaults' do
    path defaults_path
    content defaults_content
    mode '0644'
    action :nothing
  end
  ruby_block "apply #{new_resource.name} ufw rules" do
    block do
      ufw_transaction do
        defaults_file.run_action(:create)
        ufw_replay!(desired, new_resource.log_level)
      end
    end
    only_if do
      !::File.exist?(defaults_path) || ::File.binread(defaults_path) != defaults_content ||
        !::File.exist?(ufw_rules_filename) || ::File.read(ufw_rules_filename) != contents || !ufw_active?
    end
  end
  # Reconcile file permissions even when the active rules and defaults already match.
  file 'permissions for UFW defaults' do
    path defaults_path
    mode '0644'
    only_if { ::File.exist?(defaults_path) }
  end
  file ufw_rules_filename do
    content contents
    mode '0600'
  end
end

action :disable do
  execute 'disable ufw' do
    command ['ufw', '--force', 'disable']
    only_if { ufw_active? }
  end
  file ufw_rules_filename do
    content '# created by chef to allow service to start'
  end
end

action :flush do
  execute 'reset ufw' do
    command ['ufw', '--force', 'reset']
  end
  file ufw_rules_filename do
    content '# created by chef to allow service to start'
  end
end

action :delete do
  execute 'disable ufw before removal' do
    command ['ufw', '--force', 'disable']
    only_if { ::File.exist?('/usr/sbin/ufw') && ufw_active? }
  end
  [ufw_rules_filename, '/etc/default/ufw'].each do |path|
    file path do
      action :delete
    end
  end
  package 'ufw' do
    action :remove
  end
end

action :save do
  raise ArgumentError, ':save is only supported by the firewalld backend'
end

action_class do
  include FirewallCookbook::Helpers::Ufw
end
