# firewalld_zone

[Back to resource list](../README.md#resources)

## Provides

- :firewalld_zone

## Actions

- `:update`

## Properties

| Name                 | Type              | Default | Description                                                                                                                                                  |
| -----------          | -------------     | ------- | ------------------------------------                                                                                                                         |
| `description`           | `String` |         | see description tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                                               |
| `egress_priority`       | `Integer`         |         | set the zone priority for egress traffic. A lower priority value has higher precedence. Added in firewalld 2.0.0. See <https://firewalld.org/2023/04/zone-priorities> for more information. |
| `forward`               | `[true, false]`   |         | see forward tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                                                   |
| `forward_ports`         | `[Array, String]` |         | array of (port, protocol, to-port, to-addr). See forward-port tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html). |
| `icmp_block_inversion`  | `[true, false]`   |         | see icmp-block-inversion tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                                      |
| `icmp_blocks`           | `[Array, String]` |         | array of icmp-blocks. See icmp-block tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                          |
| `ingress_priority`      | `Integer`         |         | set the zone priority for ingress traffic. A lower priority value has higher precedence. Added in firewalld 2.0.0. See <https://firewalld.org/2023/04/zone-priorities> for more information. |
| `interfaces`            | `[Array, String]` |         | array of interfaces. See interface tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                            |
| `masquerade`            | `[true, false]`   |         | see masquerade tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                                                |
| `ports`                 | `[Array, String]` |         | array of port and protocol pairs. See port tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                    |
| `priority`              | `Integer`         |         | set the zone priority for both ingress and egress traffic. A lower priority value has higher precedence. Added in firewalld 2.0.0. See https://firewalld.org/2023/04/zone-priorities for more information. |
| `protocols`             | `[Array, String]` |         | array of protocols, see protocol tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                              |
| `rules_str`             | `[Array, String]` |         | array of rich-language rules. See rule tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                        |
| `services`              | `[Array, String]` |         | array of service names, see service tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                           |
| `short`                 | `String`          |         | see short tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                                                     |
| `source_ports`          | `[Array, String]` |         | array of port and protocol pairs. See source-port tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).             |
| `sources`               | `[Array, String]` |         | array of source addresses. See source tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                         |
| `target`                | `String`          |         | see target attribute of zone tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                                  |
| `version`               | `String`          |         | see version attribute of zone tag in [firewalld.zone(5)](https://firewalld.org/documentation/man-pages/firewalld.zone.html).                                 |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
