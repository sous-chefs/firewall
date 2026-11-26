# firewall

Manages a host-wide firewall backend. The default action is `:install`.

| Property | Default | Purpose |
| --- | --- | --- |
| `backend` | Platform-specific | `:ufw`, `:iptables`, `:firewalld`, `:nftables` or `:windows` |
| `enabled` | `true` | Skip operations when false |
| `log_level` | `:low` | UFW logging level |
| `ipv6_enabled` | `true` | Manage IPv6 where supported |
| `package_options` | Unset | Distribution package manager options |
| `rules` | `{}` | Additional backend-specific rule/position mappings |
| `allow_ssh`, `allow_winrm`, `allow_mosh`, `allow_loopback`, `allow_icmp` | `false` | Convenience rules from the former default recipe |
| `allow_established` | `true` | iptables and nftables established and IPv6 ICMP rules |
| `input_policy`, `forward_policy`, `output_policy` | DROP, DROP, ACCEPT | iptables and nftables policies |
| `ruleset` | Standard filter table | Complete custom iptables section/position mapping |
| `ufw_defaults` | Standard UFW defaults | Complete defaults hash, using symbol keys |
| `windows_input_policy`, `windows_output_policy` | blockinbound, allowoutbound | Windows policy |
| `windows_logging` | `{}` | Windows traffic logging by profile |

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

The explicit `:nftables` backend on Debian and RHEL-family systems owns the
entire nftables ruleset. Use one firewall manager on the host. It verifies the
configuration before writing it, reloads changes into an active packaged
service, and enables and starts an inactive service. `:restart`, `:reload`,
and `:flush` rebuild the declared ruleset. `:disable` stops and disables the
service. `:delete` also removes the managed configuration and package.
With `ipv6_enabled false`, the backend uses IPv4-only filter and NAT tables.
That mode accepts structured IPv4 rules and rejects IPv6 and raw rules.

On Windows, use `:domain`, `:private` and `:public` to select profiles, and
`:allowed` and `:blocked` to select traffic. Use `true` to enable logging and
`false` to disable it. During normal convergence, Windows logging settings
omitted from the resource, including the log path and maximum size, are
preserved across rule rebuilds. Explicit `:flush` and `:delete` retain their
reset behaviour.

The resource manages local persistent policy. Group Policy can override the
effective settings.

```ruby
firewall 'default' do
  windows_logging(
    domain: { allowed: true, blocked: true },
    private: { blocked: false }
  )
end
```
