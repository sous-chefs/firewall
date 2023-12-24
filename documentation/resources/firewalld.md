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

## Properties

There are no properties.

## Examples

```ruby
firewalld 'arbitrary-name'
end
```

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
