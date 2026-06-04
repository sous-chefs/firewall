# firewall

The `firewall` resource is a compatibility facade that delegates install,
reload, disable, flush, and rebuild actions to the selected backend resource.

## Actions

| Action     | Description                                                    |
|------------|----------------------------------------------------------------|
| `:install` | Install and enable the selected firewall backend.              |
| `:restart` | Rebuild and apply rules through the selected backend resource. |
| `:reload`  | Reload firewalld, or rebuild non-firewalld backends.           |
| `:disable` | Disable the selected firewall backend.                         |
| `:flush`   | Flush runtime rules where the selected backend supports it.    |

## Properties

| Property            | Type        | Default          | Description                                                           |
|---------------------|-------------|------------------|-----------------------------------------------------------------------|
| `backend`           | Symbol      | platform default | One of `:firewalld`, `:iptables`, `:nftables`, `:ufw`, or `:windows`. |
| `enabled`           | true, false | `true`           | Set to `false` to make the resource a no-op.                          |
| `ipv6_enabled`      | true, false | `true`           | Manage IPv6 rules for backends that support them.                     |
| `log_level`         | Symbol      | `:low`           | UFW logging level.                                                    |
| `allow_ssh`         | true, false | `false`          | Create the legacy default SSH allow rule.                             |
| `allow_winrm`       | true, false | `false`          | Create the legacy default WinRM allow rule.                           |
| `allow_mosh`        | true, false | `false`          | Create the legacy default Mosh allow rule.                            |
| `allow_loopback`    | true, false | `false`          | Create the legacy iptables loopback rule.                             |
| `allow_icmp`        | true, false | `false`          | Create the legacy iptables ICMP rule.                                 |
| `allow_established` | true, false | `true`           | Create legacy iptables established connection rules.                  |
| `iptables_ruleset`  | Hash        | see resource     | Base iptables ruleset.                                                |
| `ufw_defaults`      | Hash        | see resource     | Values rendered to `/etc/default/ufw`.                                |
| `windows_policy`    | Hash        | see resource     | Windows current-profile firewall policy.                              |

## Examples

```ruby
firewall 'default' do
  backend :iptables
  allow_ssh true
  allow_loopback true
  allow_icmp true
end
```

```ruby
firewall 'default' do
  backend :firewalld
  action :install
end
```
