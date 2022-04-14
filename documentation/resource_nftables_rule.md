# nftables_rule

## Actions

- `:create`

## Properties

| Name            | Type                                                  | Default   | Description                                                         |
| --------------- | ----------------------------------------------------- | --------- | ------------------------------------------------------------------- |
| command         | :allow :deny :drop :log :masquerade :redirect :reject | :allow    |                                                                     |
| description     | String                                                |           | name_property                                                       |
| destination     | [String, Array]                                       |           |                                                                     |
| direction       | :in :out :pre :post :forward                          | :in       |                                                                     |
| dport           | [Integer, String, Array, Range]                       |           |                                                                     |
| family          | [:ip6, :ip]                                           | :ip       |                                                                     |
| firewall_name   | String                                                | 'default' |                                                                     |
| include_comment | [true, false]                                         | true      |                                                                     |
| interface       | String                                                |           |                                                                     |
| logging         | :connections :packets                                 |           |                                                                     |
| notify_firewall | [true, false]                                         | true      |                                                                     |
| outerface       | String                                                |           |                                                                     |
| position        | Integer                                               | 50        |                                                                     |
| protocol        | [Integer, Symbol]                                     | :tcp      |                                                                     |
| raw             | String                                                |           |                                                                     |
| redirect_port   | Integer                                               |           |                                                                     |
| source          | [String, Array]                                       |           |                                                                     |
| sport           | [Integer, String, Array, Range]                       |           |                                                                     |
| stateful        | [Symbol, Array]                                       |           |                                                                     |

## Examples

See the [recipe used for testing](test/fixtures/cookbooks/nftables-test/recipes/default.rb).
