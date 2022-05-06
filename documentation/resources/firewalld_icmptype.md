# firewalld_icmptype

[Back to resource list](../README.md#resources)

## Provides

- :firewalld_icmptype

## Actions

- `:update`

## Properties

| Name                   | Name? | Type                   | Default                          | Description                                      | Allowed Values       |
| ---------------------- | ----- | ---------------------- | -------------------------------- | -------------------------------------------------| -------------------- |
|`version`               ||String                  |              `''`                    |see version attribute of icmptype tag in [firewalld.icmptype(5)](https://firewalld.org/documentation/man-pages/firewalld.icmptype.html).|                      |
|`short`                  | ✓ |String                  |                                  |see short tag in [firewalld.icmptype(5)](https://firewalld.org/documentation/man-pages/firewalld.icmptype.html).           |                      |
|`description`           ||String                  |                                  |see description tag in [firewalld.icmptype(5)](https://firewalld.org/documentation/man-pages/firewalld.icmptype.html).     |                      |
|`destinations`          ||String, Array |                                  |array, either empty or containing strings 'ipv4' and/or 'ipv6', see destination tag in [firewalld.icmptype(5)](https://firewalld.org/documentation/man-pages/firewalld.icmptype.html).| `'ipv4'`, `'ipv6'`, `'[ipv4, ipv6]'` |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
