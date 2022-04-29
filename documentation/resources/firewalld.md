# firewalld

## Actions

- `:install`
- `:reload`
- `:restart`
- `:disable`

## Properties

There are no properties.  The resource manages the
`firewalld`-services and installs `ruby-dbus` to the chef environment,
so that it may be use in the other resources later on.

## Examples

```ruby
firewalld 'arbitrary-name'
end
```

See the [recipe used for testing](../../test/fixtures/cookbooks/firewalld-test/recipes/default.rb).
