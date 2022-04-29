# firewalld_icmptype

## Actions

- `:update`

## Properties

| Name         | Type                            | Default  | Description  |
| ------       | ----                            | -------- | ------------ |
| version      | String                          |          |              |
| description  | String                          |          |              |
| destinations | ['ipv4', 'ipv6', %w(ipv4 ipv6)] | 'ipv4'   |              |


## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
