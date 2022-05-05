# firewalld_helpers

[Back to resource list](../README.md#resources)

## Provides

- :firewalld_helper

## Actions

- `:update`

## Properties

| Name                   | Name? | Type                   | Default                          | Description                                      | Allowed Values       |
| ---------------------- | ----- | ---------------------- | -------------------------------- | -------------------------------------------------| -------------------- |
|`version`               ||String                  |                                  |see version attribute of helper tag in [firewalld.helper(5)](https://firewalld.org/documentation/man-pages/firewalld.helper.html).|                      |
|`name`                  |   ✓   |String                  |                                  |see short tag in [firewalld.helper(5)](https://firewalld.org/documentation/man-pages/firewalld.helper.html).             |                      |
|`description`           ||String                  |                                  |see description tag in [firewalld.helper(5)](https://firewalld.org/documentation/man-pages/firewalld.helper.html).       |                      |
|`family`                ||String, Array  |                                  |see family tag in [firewalld.helper(5)](https://firewalld.org/documentation/man-pages/firewalld.helper.html).            | `'ipv4'`, `'ipv6'`, `'[ipv4, ipv6]'`   |
|`nf_module`             ||String                  |                                  |see module tag in [firewalld.helper(5)](https://firewalld.org/documentation/man-pages/firewalld.helper.html).            |                      |
|`ports`                 ||Array                   |                                  |array of port and protocol pairs. See port tag in [firewalld.helper(5)](https://firewalld.org/documentation/man-pages/firewalld.helper.html).|                      |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
