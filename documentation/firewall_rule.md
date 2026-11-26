# firewall_rule

Adds a rule to the previously declared named `firewall`. Default action
`:create`; `:delete` explicitly removes the rule.

```ruby
firewall_rule 'HTTPS from office' do
  firewall_name 'default'
  port 443
  source '192.0.2.0/24'
  command :allow
end
```

Common properties retain their existing names: `firewall_name` (default
`'default'`), `command` (default `:allow`), `protocol` (default `:tcp`),
`source`, `source_port`, `port`, `dest_port`, `destination`, `position`
(default 50), `description` (resource name) and `redirect_port`.
`port` is shorthand for `dest_port`; specify only one.

UFW/iptables/Windows also accept their existing `direction`, `logging`,
`interface`, `dest_interface`, `stateful`, `include_comment`, `program`,
`service`, `raw` and `notify_firewall` properties where the backend supports
them. `notify_firewall false` suppresses that rule's reconciliation request;
a parent-scheduled reconciliation still includes declared rules.

The firewalld backend retains `zone`, port arrays and ranges through D-Bus rich
rules. Omitted firewalld rules remain unchanged until explicitly removed;
collection-based backends remove omitted rules on reconciliation.

With the explicit `:nftables` backend, use `source_port` and `dest_port` for
TCP or UDP port matches, and `interface` and `dest_interface` for input and
output interfaces. `dest_port` takes precedence over `port`. Commands can be
ordered, such as `[:log, :counter, :accept]`. Set `log_prefix` and `log_group`
with `:log`. Use `raw` on its own for a complete native rule. Backend-specific
fields for UFW, firewalld and Windows are rejected on nftables.
`protocol :ipv6` matches IPv6 only. Omit `source` for all sources, or supply a
CIDR to constrain the address family and range. Comments and log prefixes
accept literal backslashes. Double quotes and control characters are rejected
because the supported nftables text parser has no escape for them.
