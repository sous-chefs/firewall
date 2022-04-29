# firewalld_policy

## Actions

- `:update`

## Properties

| Name          | Type            | Default  | Description                    |
| --------      | ----------      | -------- | ------------------------------ |
| description   | String          |          |                                |
| egress_zones  | [Array, String] |          |                                |
| forward_ports | [Array, String] |          |                                |
| icmp_blocks   | [Array, String] |          |                                |
| ingress_zones | [Array, String] |          |                                |
| masquerade    | [true, false]   |          |                                |
| ports         | [Array, String] |          |                                |
| priority      | Integer         |          |                                |
| protocols     | [Array, String] |          |                                |
| rich_rules    | [Array, String] |          |                                |
| services      | [Array, String] |          |                                |
| short         | String          |          |                                |
| source_ports  | [Array, String] |          |                                |
| target        | String          |          |                                |
| version       | String          |          |                                |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
