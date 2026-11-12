# firewalld

[Back to resource list](../README.md#resources)

The resource manages the `firewalld`-services and installs `ruby-dbus`
to the chef environment, so that it may be used in the other resources
later on.

## Provides

- :firewalld

## Actions

- `:install`
- `:reload`
- `:restart`
- `:disable`
- `:delete` stops the service and removes the firewalld package; shared dependencies remain.

## Properties

- `package_options`: optional package-manager install options.
- `dbus_gem_version`: ruby-dbus version, default `'0.25.0'`.

Install and restart wait for the D-Bus API to become ready. An already-ready API
does not report an update on repeated installation.

Package removal may retain permanent XML configuration. Delete owned D-Bus
objects explicitly before package removal when their state should also be removed.

## Examples

```ruby
firewalld 'arbitrary-name'
```

See the [recipe used for testing](../../test/cookbooks/test/recipes/firewalld_dbus.rb).
