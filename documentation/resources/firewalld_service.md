# firewalld_service

[Back to resource list](../README.md#resources)

## Provides

- :firewalld_service

## Actions

- `:update`

## Properties

| Name                   | Name? | Type                   | Default                          | Description                                      | Allowed Values       |
| ---------------------- | ----- | ---------------------- | -------------------------------- | -------------------------------------------------| -------------------- |
|`version`               ||String                  |                                  |see version attribute of service tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |
|`short`                  |✓|String                  |                                  |see short tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).            |                      |
|`description`           ||String                  |                                  |see description tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).      |                      |
|`ports`                 ||Array, String           |                                  |array of port and protocol pairs, in `["PORT/PROTOCOL"]` format. See port tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |
|`module_names`          ||Array, String           |                                  |array of kernel netfilter helpers, see module tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |
|`destination`           ||Hash                    |                                  |hash of {IP family : IP address} where 'IP family' key can be either 'ipv4' or 'ipv6'. See destination tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |
|`protocols`             ||Array, String           |                                  |array of protocols, see protocol tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |
|`source_ports`          ||Array, String           |                                  |array of port and protocol pairs, in `["PORT/PROTOCOL"]` format. See source-port tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |
|`includes`              ||Array, String           |                                  |array of service includes, see include tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |
|`helpers`               ||Array, String           |                                  |array of service helpers, see helper tag in [firewalld.service(5)](https://firewalld.org/documentation/man-pages/firewalld.service.html).|                      |

## Examples

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
