# nftables_rule

## Actions

- `:create`

## Properties

| Name            | Type                                                      | Default   | Description                                                                 |
| --------------- | --------------------------------------------------------- | --------- | --------------------------------------------------------------------------- |
| command         | :accept :counter :drop :log :masquerade :redirect :reject | :allow    |                                                                             |
| description     | String                                                    |           | name_property, can be added as comment to the nftables ruleset              |
| destination     | [String, Array]                                           |           | ip address, fqdn or a list thereof                                          |
| direction       | :in :out :pre :post :forward                              | :in       |                                                                             |
| dport           | [Integer, String, Array, Range]                           |           |                                                                             |
| family          | [:ip6, :ip]                                               | :ip       |                                                                             |
| firewall_name   | String                                                    | 'default' | Must be equal to the name of the nftables-resource.                         |
| include_comment | [true, false]                                             | true      |                                                                             |
| interface       | String                                                    |           |                                                                             |
| log_group       | [nil, Integer]                                            | nil       | If set to an integer, specify the nflog group for this rule                 |
| log_prefix      | [nil, String]                                             | nil       | If `nil`, use the name of the chain as prefix, otherwise the provided value |
| notify_firewall | [true, false]                                             | true      | When set to false, this rule will not be added to the ruleset               |
| outerface       | String                                                    |           |                                                                             |
| position        | Integer                                                   | 50        | Lower priority means earlier rule evaluation                                |
| protocol        | [Integer, Symbol]                                         | :tcp      |                                                                             |
| raw             | String                                                    |           |                                                                             |
| redirect_port   | Integer                                                   |           |                                                                             |
| source          | [String, Array]                                           |           |                                                                             |
| sport           | [Integer, String, Array, Range]                           |           |                                                                             |
| stateful        | [Symbol, Array]                                           |           |                                                                             |

## Examples

See the [recipe used for testing](../test/cookbooks/test/recipes/nftables.rb).

`protocol :ipv6` matches IPv6 only. Explicit `source` CIDRs retain their
address range and family. For example, `0.0.0.0/0` means any IPv4 source and
`::/128` matches only the unspecified IPv6 address. Omit `source` to match any
source. Comments and log prefixes accept literal backslashes and reject double
quotes and control characters, which the supported text parser cannot escape.
