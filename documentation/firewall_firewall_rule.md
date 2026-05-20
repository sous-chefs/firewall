# firewall_rule

The `firewall_rule` resource creates backend-agnostic firewall rules and
notifies the named `firewall` resource to apply them.

## Actions

| Action    | Description                          |
| --------- | ------------------------------------ |
| `:create` | Create or collect the firewall rule. |

## Properties

| Property          | Type                  | Default       | Description                                                                 |
| ----------------- | --------------------- | ------------- | --------------------------------------------------------------------------- |
| `firewall_name`   | String                | `default`     | Name of the `firewall` resource to notify.                                  |
| `command`         | Symbol                | `:allow`      | One of `:reject`, `:allow`, `:deny`, `:masquerade`, `:redirect`, or `:log`. |
| `protocol`        | Integer, Symbol       | `:tcp`        | Protocol for the rule.                                                      |
| `source`          | String                |               | Source address.                                                             |
| `source_port`     | Integer, Array, Range |               | Source port or ports.                                                       |
| `port`            | Integer, Array, Range |               | Shorthand for `dest_port`.                                                  |
| `dest_port`       | Integer, Array, Range |               | Destination port or ports.                                                  |
| `destination`     | String                |               | Destination address.                                                        |
| `position`        | Integer               | `50`          | Rule ordering position.                                                     |
| `description`     | String                | resource name | Rule description/comment.                                                   |
| `redirect_port`   | Integer               |               | Redirect target port.                                                       |
| `zone`            | String                |               | Firewalld zone.                                                             |
| `direction`       | Symbol                | `:in`         | One of `:in`, `:out`, `:pre`, or `:post`.                                   |
| `logging`         | Symbol                |               | UFW logging mode.                                                           |
| `interface`       | String                |               | Source interface.                                                           |
| `dest_interface`  | String                |               | Destination interface.                                                      |
| `stateful`        | Symbol, Array         |               | Stateful connection matching.                                               |
| `include_comment` | true, false           | `true`        | Include comments when supported.                                            |
| `program`         | String                |               | Windows program match.                                                      |
| `service`         | String                |               | Windows service match.                                                      |
| `raw`             | String                |               | Raw backend rule.                                                           |
| `notify_firewall` | true, false           | `true`        | Notify the firewall resource to apply rules.                                |

## Examples

```ruby
firewall 'default' do
  solution :ufw
end

firewall_rule 'ssh' do
  port 22
  source '0.0.0.0/0'
end
```
