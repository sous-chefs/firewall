# firewalld_rule

The `firewalld_rule` resource is the firewalld backend implementation for the
portable `firewall_rule` API. It translates common firewall rule properties into
`firewalld_rich_rule` declarations.

Use `firewalld_rule` directly when you want the portable rule shape on a
firewalld-only cookbook. Use `firewalld_rich_rule` when you want to model native
firewalld rich-rule properties directly.

## Actions

| Action    | Description                         |
|-----------|-------------------------------------|
| `:create` | Create the matching firewalld rule. |

## Examples

```ruby
firewalld_rule 'ssh' do
  port 22
  command :allow
end
```

```ruby
firewalld_rule 'redirect ssh' do
  command :redirect
  source_port 2222
  redirect_port 22
end
```
