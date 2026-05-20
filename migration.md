# Migration

## Migrating From Recipes and Attributes

This release removes the legacy `firewall::default` and
`firewall::disable_firewall` recipes. It also removes the
`node['firewall']` attribute API. Use the `firewall` resource directly and pass
configuration as resource properties.

### Default Recipe

Before:

```ruby
node.default['firewall']['solution'] = 'iptables'
node.default['firewall']['allow_ssh'] = true
node.default['firewall']['allow_mosh'] = true

include_recipe 'firewall'
```

After:

```ruby
firewall 'default' do
  solution :iptables
  allow_ssh true
  allow_mosh true
end
```

### Disabling the Firewall

Before:

```ruby
include_recipe 'firewall::disable_firewall'
```

After:

```ruby
firewall 'default' do
  action :disable
end
```

### Backend Defaults

The `firewall` resource chooses the same platform-family defaults previously
provided by attributes:

* Debian: `:nftables`
* Ubuntu: `:ufw`
* Amazon Linux, Fedora, RHEL-family, and SUSE-family: `:firewalld`
* Windows: `:windows`
* Other platforms: `:iptables`

Set `solution` explicitly when you need a different backend.

The `firewall` resource can select `:nftables` and maps `firewall_rule`
resources to nftables rules when selected. The dedicated `nftables` and
`nftables_rule` resources remain available for direct nftables management when
you need nftables-specific properties or chain policy control.

### Default Rule Properties

The legacy attributes map to resource properties:

| Removed attribute                                   | Resource property   |
| --------------------------------------------------- | ------------------- |
| `node['firewall']['allow_ssh']`                     | `allow_ssh`         |
| `node['firewall']['allow_winrm']`                   | `allow_winrm`       |
| `node['firewall']['allow_mosh']`                    | `allow_mosh`        |
| `node['firewall']['allow_loopback']`                | `allow_loopback`    |
| `node['firewall']['allow_icmp']`                    | `allow_icmp`        |
| `node['firewall']['allow_established']`             | `allow_established` |
| `node['firewall']['ipv6_enabled']`                  | `ipv6_enabled`      |
| `node['firewall']['iptables']['defaults']`          | `iptables_ruleset`  |
| `node['firewall']['ufw']['defaults']`               | `ufw_defaults`      |
| `node['firewall']['windows']['defaults']['policy']` | `windows_policy`    |

Test cookbook examples live under `test/cookbooks/test/recipes/`.
