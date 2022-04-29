# firewalld_ipset

## Actions

- `:update`

## Properties

| Name        | Type            | Default     | Description                             |
| ------      | ------          | --------    | --------------------------------------- |
| version     | String          |             |                                         |
| description | String          |             |                                         |
| type        | String          | `'hash:ip'` |                                         |
| options     | [Hash]          |             |                                         |
| entries     | [Array, String] |             |                                         |


## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
