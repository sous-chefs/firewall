# firewalld_config

[Back to resource list](../README.md#resources)

## Provides

- :firewalld_config

## Actions

- `:update`

## Properties

| Name                   | Name? | Type                   | Default                          | Description                                      | Allowed Values       |
| ---------------------- | ----- | ---------------------- | -------------------------------- | -------------------------------------------------| -------------------- |
|`default_zone`          ||String                  |                                  |Set default zone for connections and interfaces where no zone has been selected to zone. Setting the default zone changes the zone for the connections or interfaces, that are using the default zone.|                      |
|`log_denied`            ||all, unicast, broadcast, multicast, off|                                  |Set LogDenied value to value. If LogDenied is enabled, then logging rules are added right before reject and drop rules in the INPUT, FORWARD and OUTPUT chains for the default rules and also final reject and drop rules in zones.|                      |

## Examples

```ruby
firewalld_config 'some values' do
  default_zone 'DROP'
  log_deniad 'all'
end
```

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
