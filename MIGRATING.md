# Migrating to cookbook 8

Full custom resources replace the root recipes, node attributes and legacy
`Chef::Resource::Firewall` / provider classes. Chef/Cinc 18+ is the runtime
baseline. Public resource names and the default backend selection are preserved.

Replace `include_recipe 'firewall'` with `firewall 'default'` in a wrapper
cookbook. Replace `firewall::disable_firewall` with `firewall 'default' do
action :disable; end`.

## Attributes become properties

| Attribute below `node['firewall']` | Property on `firewall` |
| --- | --- |
| `solution` | `backend`, as a symbol |
| `allow_ssh`, `allow_winrm`, `allow_mosh`, `allow_loopback`, `allow_icmp` | Same property names, default `false` |
| `allow_established` | `allow_established`, default `true` |
| `ipv6_enabled` | `ipv6_enabled`, default `true` |
| `iptables.defaults.policy.input` | `input_policy`, default `'DROP'` |
| `iptables.defaults.policy.forward` | `forward_policy`, default `'DROP'` |
| `iptables.defaults.policy.output` | `output_policy`, default `'ACCEPT'` |
| `iptables.defaults.ruleset` | `ruleset` |
| `ufw.defaults` | `ufw_defaults`, complete hash with symbol keys |
| `windows.defaults.policy.input` | `windows_input_policy`, default `'blockinbound'` |
| `windows.defaults.policy.output` | `windows_output_policy`, default `'allowoutbound'` |

The default recipe's convenience rules now belong to the `firewall` resource.
Loopback, ICMP, established connections and IPv6 ICMP convenience rules are
iptables-specific, as before. SSH/Mosh and Windows WinRM remain opt-in.

## Rule ownership and lifecycle

Declare the root `firewall` resource before its rules, and use `firewall_name`
to associate rules with it. UFW, iptables and Windows collect rules only for that
named firewall and reconcile once at the end of the converge. Omitting or deleting
a rule removes it from the next managed ruleset. The parent also reconciles an
empty ruleset, so the last removed rule does not remain installed.

The firewalld backend still manages individual permanent D-Bus rich rules.
Omission leaves those rules unchanged, as before; use `firewall_rule :delete`
or `firewalld_rich_rule :remove` for explicit removal. Zones and port arrays are
preserved. Unsupported firewalld properties raise an error rather than producing
a broader rule.

`firewall :delete` stops Linux backend services and removes their packages and
managed state files. Windows resets the managed firewall configuration and keeps
the built-in service. `:flush` is supported by UFW, iptables and Windows;
`:reload` is firewalld-specific. The D-Bus object resources also support
explicit `:delete` actions. Shared dependencies such as D-Bus are retained.

Package removal may retain permanent firewalld XML configuration. Remove owned
objects explicitly with their `:delete` actions or rich-rule `:remove` before
removing the package when those objects should also be removed.

iptables NAT rules use actual NAT restore sections. Removing their last rule
clears that section; disable/delete clears all recorded managed tables and
restores their built-in chain policies to ACCEPT. nftables validates generated
configuration before replacing it. Update status comes from actual package,
service, file or rule changes, so rule collection itself is idempotent.

## D-Bus details

The standalone `firewalld_rich_rule` API and all zone priority properties remain
available. New zones retain forwarding disabled unless explicitly enabled.
Explicit `false` values are honoured; tuple-valued ports and rich-rule quoting
are normalised for repeat convergence. Default descriptions use resource names.
Unknown settings from newer firewalld servers are ignored unless exposed as
properties. Rich-rule local forwarding supplies IPv4 when no address selects a
family.

## Platforms

Obsolete Amazon Linux 2, Debian 11 and openSUSE Leap 15 CI images are retired.
Their platform families remain covered by current versions. Ubuntu 20.04 remains
an ESM option. Windows keeps a native CI job. No lifecycle test should use host
networking or run against production rules.
