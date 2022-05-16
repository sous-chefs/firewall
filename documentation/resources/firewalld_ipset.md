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
|`short`                  |✓|String                  |                                  |see short tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).              |                      |
|`description`           ||String                  |                                  |see description tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).        |                      |
|`type`                  ||String                  |                                  |see type attribute of ipset tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).|  `'hash:ip'` `'hash:ip,mark'` `'hash:ip,port'` `'hash:ip,port,ip'` `'hash:ip,port,net'` `'hash:mac'` `'hash:net'` `'hash:net,iface'` `'hash:net,net'` `'hash:net,port'` `'hash:net,port,net'`   |
|`options`               ||Hash                    |                                  |hash of {option : value} . See options tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).|                      |
|`entries`               ||Array, String           |                                  |array of entries, see entry tag in [firewalld.ipset(5)](https://firewalld.org/documentation/man-pages/firewalld.ipset.html).|                      |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
