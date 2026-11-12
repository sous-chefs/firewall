# firewall

Manages a host-wide firewall backend. The default action is `:install`.

| Property | Default | Purpose |
| --- | --- | --- |
| `backend` | Platform-specific | `:ufw`, `:iptables`, `:firewalld` or `:windows` |
| `enabled` | `true` | Skip operations when false |
| `log_level` | `:low` | UFW logging level |
| `ipv6_enabled` | `true` | Manage IPv6 where supported |
| `package_options` | Unset | Distribution package manager options |
| `rules` | `{}` | Additional backend-specific rule/position mappings |
| `allow_ssh`, `allow_winrm`, `allow_mosh`, `allow_loopback`, `allow_icmp` | `false` | Convenience rules from the former default recipe |
| `allow_established` | `true` | iptables established and IPv6 ICMP rules |
| `input_policy`, `forward_policy`, `output_policy` | DROP, DROP, ACCEPT | iptables policies |
| `ruleset` | Standard filter table | Complete custom iptables section/position mapping |
| `ufw_defaults` | Standard UFW defaults | Complete defaults hash, using symbol keys |
| `windows_input_policy`, `windows_output_policy` | blockinbound, allowoutbound | Windows policy |

Actions: `:install`, `:restart`, `:disable`, `:delete`; `:flush` on
UFW/iptables/Windows and `:reload` on firewalld. Linux installation creates
backend packages and services. Deletion removes managed backend configuration
and packages; shared dependencies remain. Windows keeps its built-in service.

firewalld package removal may retain permanent XML configuration. Use the
individual D-Bus object deletion actions before package removal to remove those
objects explicitly.

```ruby
firewall 'default' do
  backend :iptables
  allow_ssh true
end
```

Allow access for management before applying restrictive policies. Each backend
controls host-wide state; resource names do not provide independent firewalls.
