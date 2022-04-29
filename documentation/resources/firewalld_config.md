# firewalld_config

## Actions

- `:update`

## Properties

| Name           | Type                                              | Default  | Description                     |
| -------------- | ------------------------------------------------- | -------- | ------------------------------- |
| default_zone   | String                                            | default  | Set the default zone.           |
| log_denied     | 'all', 'unicast', 'broadcast', 'multicast', 'off' |          | configure which packages to log |
|                |                                                   |          |                                 |

## Examples

```ruby
firewalld_config 'some values' do
  default_zone 'DROP'
  log_deniad 'all'
end
```

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
