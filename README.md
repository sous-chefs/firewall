# firewall Cookbook

[![Cookbook Version](https://img.shields.io/cookbook/v/firewall.svg)](https://supermarket.chef.io/cookbooks/firewall)
[![CI State](https://github.com/sous-chefs/firewall/workflows/ci/badge.svg)](https://github.com/sous-chefs/firewall/actions?query=workflow%3Aci)
[![OpenCollective](https://opencollective.com/sous-chefs/backers/badge.svg)](#backers)
[![OpenCollective](https://opencollective.com/sous-chefs/sponsors/badge.svg)](#sponsors)
[![License](https://img.shields.io/badge/License-Apache%202.0-green.svg)](https://opensource.org/licenses/Apache-2.0)

Provides a set of primitives for managing firewalls and associated rules.

PLEASE NOTE - The resource/providers in this cookbook are under heavy development. An attempt is being made to keep the resource simple/stupid by starting with less sophisticated firewall implementations first and refactor/vet the resource definition with each successive provider.

## Maintainers

This cookbook is maintained by the Sous Chefs. The Sous Chefs are a community of Chef cookbook maintainers working together to maintain important cookbooks. If you’d like to know more please visit [sous-chefs.org](https://sous-chefs.org/) or come chat with us on the Chef Community Slack in [#sous-chefs](https://chefcommunity.slack.com/messages/C2V7B88SF).

## Requirements

- Chef Infra Client 15.5+

```ruby
depends 'firewall'
```

## Supported firewalls and platforms

- [UFW (Uncomplicated Firewall)](https://help.ubuntu.com/community/UFW)
- [Firewalld](https://firewalld.org/)
- [IPTables](https://manpages.debian.org/stable/iptables/iptables.8.en.html)
- [Windows Firewall](https://learn.microsoft.com/en-us/windows/security/operating-system-security/network-security/windows-firewall/)
- [nftables](https://wiki.nftables.org/wiki-nftables/index.php/Main_Page)

The default firewall solution used on Linux is based on the platform family:

| Platform Family | Default Firewall Solution |
|-----------------|---------------------------|
| `amazon`        | firewalld                 |
| `debian`        | ufw                       |
| `fedora`        | firewalld                 |
| `rhel`          | firewalld                 |
| `suse`          | firewalld                 |
| `ubuntu`        | ufw                       |
| `windows`       | windows                   |
| Other           | iptables                  |

If you'd like to use a firewall solution other than the platform's default, set the `default['firewall']['solution']`
attribute to the desired firewall:

```ruby
# firewalld
default['firewall']['solution'] = 'firewalld'

# iptables
default['firewall']['solution'] = 'iptables'

# ufw
default['firewall']['solution'] = 'ufw'
```

### nftables

In order to use nftables, just use the resource `nftables` and
`nftables_rule`.  These resources are written in more modern design
styles and are not configurable by node attributes.

### Supported operating systems

See the [kitchen.yml](https://github.com/sous-chefs/firewall/blob/main/kitchen.yml) for the full matrix of platforms
this cookbook is tested on.

## Quickstart

To simply open a port in the system's default firewall:

```ruby
include_recipe 'firewall'

firewall_rule 'ssh' do
  port 22
end
```

## How it works

The most basic use involves two resources, `firewall` and `firewall_rule`. The typical usage scenario is as follows:

- include the `'firewall::default'` recipe or run the `:install` action on the `firewall` resource named `'default'`, which installs appropriate packages and configures services to start on boot and starts them.
- run the `:create` action on every `firewall_rule` resource, which adds to the list of rules that should be configured on the firewall. How the rules are implemented depends on the firewall platform:
  - **firewalld**: `firewall_rule` implements the rules under the hood as firewalld [rich rules](https://firewalld.org/documentation/man-pages/firewalld.richlanguage.html) in the system's default zone.
  - **iptables, ufw, windows**: `firewall_rule` automatically sends a delayed notification to the `firewall['default']` resource to run the `:restart` action.
    - when the delayed `:restart` notification on the `firewall` resource fires, if any rules are different than the last run, the provider will update the current state of the firewall rules to match the expected rules.

There is a fundamental mismatch between the idea of a Chef action and the action that should be taken on a firewall
rule. For this reason, the Chef action for a `firewall_rule` may be `:create` (the rule should be present in the
firewall) but the action taken on a packet in a firewall (`DROP`, `ACCEPT`, etc) is denoted as a `command` property on
the `firewall_rule` resource.

The same points hold for the `nftables`- and `nftables_rule`-resources.

## iptables considerations

If you need to use a table other than `*filter`, the best way to do so is like so:

```ruby
node.default['firewall']['iptables']['defaults'][:ruleset] = {
  '*filter' => 1,
  ':INPUT DROP' => 2,
  ':FORWARD DROP' => 3,
  ':OUTPUT ACCEPT_FILTER' => 4,
  'COMMIT_FILTER' => 100,
  '*nat' => 101,
  ':PREROUTING DROP' => 102,
  ':POSTROUTING DROP' => 103,
  ':OUTPUT ACCEPT_NAT' => 104,
  'COMMIT_NAT' => 200
}
```

Note -- in order to support multiple hash keys containing the same rule, anything found after the underscore will be stripped for: `:OUTPUT :INPUT :POSTROUTING :PREROUTING COMMIT`. This allows an example like the above to be reduced to just repeated lines of `COMMIT` and `:OUTPUT ACCEPT` while still avoiding duplication of other things.

Then it's trivial to add additional rules to the `*nat` table using the raw parameter:

```ruby
firewall_rule "postroute" do
  raw "-A POSTROUTING -o eth1 -p tcp -d 172.28.128.21 -j SNAT --to-source 172.28.128.6"
  position 150
end
```

Note that any line starting with `COMMIT` will become just `COMMIT`, as hash
keys must be unique but we need multiple commit lines.

## nftables

Please read the documentation for the
[`nftables` resource](documentation/resource_nftables.md) and the
[`nftables_rule` resource](documentation/resource_nftables_rule.md)

## firewalld

For most rules it's sufficient to simply use the `firewall_rule` resource which is a platform-agnostic way to add
firewall rules. On firewalld systems it adds rules to the default zone as firewalld [rich
rules](https://firewalld.org/documentation/man-pages/firewalld.richlanguage.html). See the
[`firewall_rule`](#firewall_rule) section for examples.

See the [`firewalld` resources](documentation/README.md) documentation for advanced firewalld configuration.

## Recipes

### `firewall::default`

The default recipe creates a firewall resource with action install.

### `firewall::disable_firewall`

Used to disable platform specific firewall. Many clouds have their own firewall configured outside of the OS instance such as AWS Security Groups.

## Attributes

- `default['firewall']['solution'] = <firewalld|iptables|ufw>`, sets the firewall solution to use on Linux platforms. Defaults to the default firewall solution used by the platform family. See [Supported firewalls and platforms](#supported-firewalls-and-platforms) for more info.
- `default['firewall']['allow_ssh'] = false`, set true to open port 22 for SSH when the default recipe runs
- `default['firewall']['allow_mosh'] = false`, set to true to open UDP ports 60000 - 61000 for [Mosh][0] when the default recipe runs
- `default['firewall']['allow_winrm'] = false`, set true to open port 5989 for WinRM when the default recipe runs
- `default['firewall']['allow_loopback'] = false`, set to true to allow all traffic on the loopback interface
- `default['firewall']['allow_icmp'] = false`, set true to allow icmp protocol on supported OSes (note: ufw and windows implementations don't support this)
- `default['firewall']['ufw']['defaults']` hash for template `/etc/default/ufw`
- `default['firewall']['iptables']['defaults']` hash for default policies for 'filter' table's chains`
- `default['firewall']['windows']['defaults']` hash to define inbound / outbound firewall policy on Windows platform
- `default['firewall']['allow_established'] = true`, set to false if you don't want a related/established default rule on iptables
- `default['firewall']['ipv6_enabled'] = true`, set to false if you don't want IPv6 related/established default rule on iptables (this enables ICMPv6, which is required for much of IPv6 communication)

## Resources

### `firewall`

It's not recommended to use this resource directly. Instead simply `include_recipe 'firewall'` and then add your desired
`firewall_rule` resources. See the [`firewall_rule`](#firewall_rule) section for examples.

***NB***: The name 'default' of this resource is important as it is used for firewall_rule providers to locate the firewall resource. If you change it, you must also supply the same value to any firewall_rule resources using the `firewall_name` parameter.

#### Actions

- `:install` (*default action*): Install and Enable the firewall. This will ensure the appropriate packages are installed and that any services have been started.
- `:reload`: *firewalld only*. Reloads the runtime state to match the permanent configuration. All runtime-only rules are flushed out.
- `:disable`: Disable the firewall. Drop any rules and put the node in an unprotected state. Flush all current rules. Also erase any internal state used to detect when rules should be applied.
- `:flush`: *Except firewalld*. Flush all current rules. Also erase any internal state used to detect when rules should be applied.

#### Properties

- `enabled` (default to `true`): If set to `false`, all actions will no-op on this resource. This is a way to prevent
  included cookbooks from configuring a firewall.
- `ipv6_enabled` (default to `true`): *Iptables only*. If set to false, firewall will not perform any ipv6 related work.
- `log_level`: UFW only. Level of verbosity the firewall should log at. valid values are: :low, :medium, :high, :full, :off. default is :low.
- `package_options`: Pass additional options to the package manager when installing the firewall.

```ruby
# all defaults
firewall 'default'

# enable platform default firewall
firewall 'default' do
  action :install
end

# increase logging past default of 'low'
firewall 'default' do
  log_level :high
  action    :install
end
```

### `firewall_rule`

#### Actions

- `:create`: Create the firewall rule and notify the firewall to reload after the rule has been saved. On firewalld systems, the rules are added to the default zone as firewalld [rich rules](https://firewalld.org/documentation/man-pages/firewalld.richlanguage.html).

#### Properties

```ruby
firewall_rule 'name' do
  firewall_name   String            # Default: 'default'
  command         Symbol            # Default: :allow
  protocol        Integer, Symbol   # Default: :tcp
  source          String
  source_port     Integer, Array, Range
  port            Integer, Array, Range
  dest_port       Integer, Array, Range
  destination     String
  position        Integer           # Default: 50
  description     String            # Default: 'name' unless specified

  # Firewall-specific properties
  zone            String            # Firewall: firewalld
  logging         Symbol            # Firewall: ufw
  redirect_port   Integer           # Firewall: iptables, firewalld
  dest_interface  String            # Firewall: iptables, windows
  interface       String            # Firewall: iptables, ufw, windows
  include_comment true, false       # Firewall: iptables, ufw. Default: true
  stateful        Symbol, Array     # Firewall: iptables, ufw
  raw             String            # Firewall: iptables, ufw
  direction       Symbol            # Firewall: iptables, ufw, windows. Default: :in
  notify_firewall true, false       # Firewall: iptables, ufw, windows. Default: true
  program         String            # Firewall: windows
  service         String            # Firewall: windows
end
```

Firewall-agnostic properties that can be used with `firewall_rule` on any firewall system:

- `firewall_name`: the matching firewall resource that this rule applies to. Default value: `default`
- `description` (*default: same as rule name*): Used to provide a comment that will be included when adding the firewall rule.
- `command`: What action to take on a particular packet
   - `:allow` (*default action*): the rule should allow matching packets
   - `:deny`: the rule should deny (drop) matching packets
   - `:reject`: the rule should reject matching packets
   - `:masquerade`: Masquerade the matching packets
   - `:redirect`: Redirect the matching packets
   - `:log`: Configure logging
- `protocol`: `:tcp` (*default*), `:udp`, `:icmp`, `:none`, or protocol number. Using protocol numbers is not supported
  using the ufw provider (default for debian/ubuntu systems).
- `source` (*Default is `0.0.0.0/0` or `Anywhere`*): source ip address or subnet to filter.
- `source_port` (*Default is nil*): source port for filtering packets.
- `port` or `dest_port`: target port number (ie. `22` to allow inbound SSH), an array of incoming port numbers (ie.
  `[80,443]` to allow inbound HTTP & HTTPS), or a range of incoming ports `(12000..12100)`.
- `destination`: ip address or subnet to filter on packet destination, must be a valid IP
- `position` (*default: 50*): **relative** position to insert rule at. Position may be any integer between 0 < n < 100 (exclusive), and more than one rule may specify the same position.

Additional properties for advanced firewall rules that tied to specific firewall solutions. **Note: These properties are *not* firewall-agnostic, so you must ensure they are used only on the appropriate firewall solutions**:

- `zone`: (*firewalld*), a string, such as `public` that the rule will be applied. Defaults to the system's configured
  default zone.
- `logging` (*ufw*): may be added to enable logging for a particular rule. valid values are: `:connections`, `:packets`.
  In the ufw provider, `:connections` logs new connections while `:packets` logs all packets.
- `redirect_port` (*iptables, firewalld*): redirected port for rules with command `:redirect`.
- `dest_interface` (*iptables, windows*): interface where packets may be destined to go.
- `interface` (*iptables, ufw, windows*): (source) interface to apply rule (ie. `eth0`).
- `include_comment` (*iptables, ufw*): Used to optionally exclude the comment in the rule. Default: `true`.
- `stateful` (*iptables, ufw*): a symbol or array of symbols, such as ``[:related, :established]` that will be passed to the state module in iptables or firewalld.
- `raw` (*iptables, ufw*): Used to pass an entire rule as a string, omitting all other parameters. This line will be directly loaded by `iptables-restore`/fed directly into `ufw` on the command line.
- `direction` (*iptables, ufw, windows*): Direction of the rule. Valid values are: `:in` (*default*), `:out`, `:pre`,
`:post`.
- `notify_firewall` (*iptables, ufw, windows*): Notify the firewall to recalculate (and potentially reapply) the
  `firewall_rule`(s) it finds. Default: `true`

#### Examples

```ruby
include_recipe 'firewall'

# open standard ssh port
firewall_rule 'ssh' do
  port     22
  command  :allow
end

# open standard http port to tcp traffic only; insert as first rule
firewall_rule 'http' do
  port     80
  protocol :tcp
  position 1
  command   :allow
end

# open UDP ports 60000..61000 for mobile shell (mosh.org), note
# that the protocol attribute is required when using port_range
firewall_rule 'mosh' do
  protocol    :udp
  port        60000..61000
  command     :allow
end

# open multiple ports for http/https, note that the protocol
# attribute is required when using ports
firewall_rule 'http/https' do
  protocol :tcp
  port     [80, 443]
  command   :allow
end

# firewalld example of opening port 22 on public zone
firewall_rule 'ssh' do
  port    22
  zone    "public"
  command :allow
end
```

## Troubleshooting

To figure out what the position values are for current rules, print the hash that contains the weights:

```ruby
require pp
default_firewall = resources(:firewall, 'default')
pp default_firewall.rules
```

## Development

This section details "quick development" steps. For a detailed explanation, see [[Contributing.md]].

1. Clone this repository from GitHub:

`$ git clone git@github.com:chef-cookbooks/firewall.git`

1. Create a git branch

`$ git checkout -b my_bug_fix`

1. Install dependencies:

`$ bundle install`

1. Make your changes/patches/fixes, committing appropiately
1. **Write tests**
1. Run the tests:

- `bundle exec foodcritic -f any .`
- `bundle exec rspec`
- `bundle exec rubocop`
- `bundle exec kitchen test`

In detail:

- Foodcritic will catch any Chef-specific style errors
- RSpec will run the unit tests
- Rubocop will check for Ruby-specific style errors
- Test Kitchen will run and converge the recipes

## Contributors

This project exists thanks to all the people who [contribute.](https://opencollective.com/sous-chefs/contributors.svg?width=890&button=false)

### Backers

Thank you to all our backers!

![https://opencollective.com/sous-chefs#backers](https://opencollective.com/sous-chefs/backers.svg?width=600&avatarHeight=40)

### Sponsors

Support this project by becoming a sponsor. Your logo will show up here with a link to your website.

![https://opencollective.com/sous-chefs/sponsor/0/website](https://opencollective.com/sous-chefs/sponsor/0/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/1/website](https://opencollective.com/sous-chefs/sponsor/1/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/2/website](https://opencollective.com/sous-chefs/sponsor/2/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/3/website](https://opencollective.com/sous-chefs/sponsor/3/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/4/website](https://opencollective.com/sous-chefs/sponsor/4/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/5/website](https://opencollective.com/sous-chefs/sponsor/5/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/6/website](https://opencollective.com/sous-chefs/sponsor/6/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/7/website](https://opencollective.com/sous-chefs/sponsor/7/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/8/website](https://opencollective.com/sous-chefs/sponsor/8/avatar.svg?avatarHeight=100)
![https://opencollective.com/sous-chefs/sponsor/9/website](https://opencollective.com/sous-chefs/sponsor/9/avatar.svg?avatarHeight=100)

[0]: https://mosh.org
