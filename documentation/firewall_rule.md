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
