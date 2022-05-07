# firewalld_policy

[Back to resource list](../README.md#resources)

## Provides

- :firewalld_policy

## Actions

- `:update`

## Properties

| Name          | Type              | Default  | Description                                                                                                                                                      |
| --------      | ----------        | -------- | ------------------------------                                                                                                                                   |
| `description` | `String`          |          | see description tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                                               |
| `egress_zones`   | `[Array, String]` |          | array of zone names. See egress-zone tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                          |
| `forward_ports`  | `[Array, String]` |          | array of [port, protocol, to-port, to-addr]. See forward-port tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html). |
| `icmp_blocks`    | `[Array, String]` |          | array of icmp-blocks. See icmp-block tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                          |
| `ingress_zones`  | `[Array, String]` |          | array of zone names. See ingress-zone tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                         |
| `masquerade`     | `[true, false]`   |          | see masquerade tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                                                |
| `ports`          | `[Array, String]` |          | array of port and protocol pairs. See port tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                    |
| `priority`       | `Integer`         |          | see priority tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                                                  |
| `protocols`      | `[Array, String]` |          | array of protocols, see protocol tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                              |
| `rich_rules`     | `[Array, String]` |          | array of rich-language rules. See rule tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                        |
| `services`       | `[Array, String]` |          | array of service names, see service tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                           |
| `short`          | `String`          |          | see short tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                                                     |
| `source_ports`   | `[Array, String]` |          | array of port and protocol pairs. See source-port tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).             |
| `target`         | `String`          |          | see target attribute of policy tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                                |
| `version`        | `String`          |          | see version attribute of policy tag in [firewalld.policy(5)](https://firewalld.org/documentation/man-pages/firewalld.policy.html).                               |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
