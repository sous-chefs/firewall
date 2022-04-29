# firewalld_helpers

## Actions

- `:update`

## Properties

| Name        | Type                               | Default | Description  |
| ------      | ------                             | ------- | ------------ |
| version     | String                             |         |              |
| description | String                             |         |              |
| family      | ['ipv4', 'ipv6', ['ipv4', 'ipv6']] | 'ipv4'  |              |
| nf_module   | String                             |         |              |
| ports       | Array                              |         |              |

## Examples

TODO

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
