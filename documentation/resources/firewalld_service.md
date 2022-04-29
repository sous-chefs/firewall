# firewalld_service

## Actions

- `:update`

## Properties

| Name           | Type               | Default  | Description                                                      |
| -------------- | ------------------ | -------- | ---------------------------------------------------------------- |
| version        | String             |          |                                                                  |
| description    | String             |          |                                                                  |
| ports          | [Array, String]    |          |                                                                  |
| module_names   | [Array, String]    |          |                                                                  |
| destination    | Hash               |          |                                                                  |
| protocols      | [Array, String]    |          |                                                                  |
| source_ports   | [Array, String]    |          |                                                                  |
| includes       | [Array, String]    |          |                                                                  |
| helpers        | [Array, String]    |          |                                                                  |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
