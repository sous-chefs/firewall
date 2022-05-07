# firewalld_ipset

[Back to resource list](../README.md#resources)

## Provides

- :firewalld_ipset

## Actions

- `:update`

## Properties

| Name                   | Name? | Type                   | Default                          | Description                                      | Allowed Values       |
| ---------------------- | ----- | ---------------------- | -------------------------------- | -------------------------------------------------| -------------------- |
|`version`               ||String                  |                                  |see version attribute of ipset tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).|                      |
|`name`                  ||String                  |                                  |see short tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).              |                      |
|`description`           ||String                  |                                  |see description tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).        |                      |
|`type`                  ||String                  |                                  |see type attribute of ipset tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).|                      |
|`options`               ||Hash                    |                                  |hash of {option : value} . See options tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).|                      |
|`entries`               ||Array, String           |                                  |array of entries, see entry tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).|                      |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
