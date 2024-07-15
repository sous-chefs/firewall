# firewall Cookbook CHANGELOG

This file is used to list changes made in each version of the firewall cookbook.

## 6.3.7 - *2024-07-15*

Standardise files with files in sous-chefs/repo-management

Standardise files with files in sous-chefs/repo-management

## 6.3.6 - *2024-05-06*

## 6.3.5 - *2024-05-06*

Added support for firewalld zone attribute

## 6.3.4 - *2023-12-21*

## 6.3.3 - *2023-09-28*

## 6.3.2 - *2023-09-04*

## 6.3.1 - *2023-08-30*

## 6.3.0 - *2023-08-01*

- Default to `firewalld` on EL8

## 6.2.18 - *2023-07-31*

Fixes typo in FORWARD chain of nftables default ruleset

## 6.2.17 - *2023-07-10*

## 6.2.16 - *2023-05-17*

## 6.2.15 - *2023-04-26*

Update CI runner to MacOS 12

## 6.2.14 - *2023-04-17*

## 6.2.13 - *2023-04-11*

Fix documentation to pass markdown lint

## 6.2.12 - *2023-04-07*

Standardise files with files in sous-chefs/repo-management

## 6.2.11 - *2023-04-04*

Fixed a typo in the readme

## 6.2.10 - *2023-04-01*

## 6.2.9 - *2023-04-01*

## 6.2.8 - *2023-04-01*

Standardise files with files in sous-chefs/repo-management

Standardise files with files in sous-chefs/repo-management

## 6.2.7 - *2023-03-02*

## 6.2.6 - *2023-02-23*

Standardise files with files in sous-chefs/repo-management

## 6.2.5 - *2023-02-16*

Standardise files with files in sous-chefs/repo-management

## 6.2.4 - *2023-02-15*

Standardise files with files in sous-chefs/repo-management

## 6.2.3 - *2022-12-08*

Standardise files with files in sous-chefs/repo-management

## 6.2.2 - *2022-12-08*

Standardise files with files in sous-chefs/repo-management

## 6.2.1 - *2022-12-02*

## 6.2.0 - *2022-12-02*

- Add support for for the description attribute when using UFW

## 6.1.0 - *2022-09-15*

- Add filepath selection based on OS for nftables.conf

## 6.0.2 - *2022-05-15*

Standardise files with files in sous-chefs/repo-management

## 6.0.1 - *2022-05-13*

- Standardise files with files in sous-chefs/repo-management

## 6.0.0 - *2022-05-09*

- Values for firewalld resources must be specified as one would
  specify them to `firewall-cmd`.
- Do not use begin/rescue blocks when adding firewalld-objects, as
  that resulted in errors being logged by firewalld.
- Various bug fixes that were found along the way.

## 5.1.0 - *2022-05-07*

- Add new providers for firewalld using the dbus-interface of firewalld.

## 5.0.0 - *2022-04-20*

- Add support for nftables

## 4.0.3 - *2022-04-11*

- Use resuable workflows instead of Chef Delivery

## 4.0.2 - *2022-02-17*

- Standardise files with files in sous-chefs/repo-management
- Remove delivery folder

## 4.0.1 - *2022-01-07*

- Remove extraneous task file that's no longer needed

## 4.0.0 - *2021-09-09*

- Remove dependency on chef-sugar cookbook
- Bump to require Chef Infra Client >= 15.5 for chef-utils
- Update metadata and README to Sous Chefs

## 3.0.2 - *2021-08-30*

- Standardise files with files in sous-chefs/repo-management

## 3.0.1 - *2021-07-08*

- Restart netfilter service in iptables mode after updating firewall rules

## 3.0.0 - *2021-06-14*

- Add Amazon Linux support
- Fix firewall resource actions list
- First attempt to modernize testing
- Various Cookstyle fixes

## 2.7.1 - *2021-06-01*

- resolved cookstyle error: libraries/helpers_windows.rb:47:9 convention: `Style/RedundantAssignment`
- resolved cookstyle error: libraries/helpers_windows.rb:48:9 convention: `Layout/IndentationWidth`
- resolved cookstyle error: libraries/helpers_windows.rb:49:16 convention: `Layout/ElseAlignment`
- resolved cookstyle error: libraries/helpers_windows.rb:50:9 convention: `Layout/IndentationWidth`
- resolved cookstyle error: libraries/helpers_windows.rb:51:16 warning: `Layout/EndAlignment`
- resolved cookstyle error: libraries/helpers_windows.rb:52:1 convention: `Layout/EmptyLinesAroundMethodBody`
- resolved cookstyle error: libraries/helpers_windows.rb:52:1 convention: `Layout/TrailingWhitespace`
- resolved cookstyle error: libraries/provider_firewall_firewalld.rb:30:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_firewalld.rb:54:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_firewalld.rb:114:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_firewalld.rb:136:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_firewalld.rb:149:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables.rb:33:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables.rb:63:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables.rb:112:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables.rb:134:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu.rb:34:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu.rb:67:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu.rb:133:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu.rb:156:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu1404.rb:34:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu1404.rb:67:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu1404.rb:133:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_iptables_ubuntu1404.rb:156:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_rule.rb:24:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_ufw.rb:32:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_ufw.rb:61:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_ufw.rb:102:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_ufw.rb:115:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_windows.rb:29:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_windows.rb:42:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_windows.rb:97:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: libraries/provider_firewall_windows.rb:118:5 refactor: `ChefModernize/ActionMethodInResource`
- resolved cookstyle error: attributes/iptables.rb:8:54 refactor: `ChefStyle/AttributeKeys`
- resolved cookstyle error: attributes/iptables.rb:8:54 convention: `Style/StringLiteralsInInterpolation`
- resolved cookstyle error: attributes/iptables.rb:8:63 refactor: `ChefStyle/AttributeKeys`
- resolved cookstyle error: attributes/iptables.rb:8:64 convention: `Style/StringLiteralsInInterpolation`
- resolved cookstyle error: attributes/iptables.rb:9:56 refactor: `ChefStyle/AttributeKeys`
- resolved cookstyle error: attributes/iptables.rb:9:56 convention: `Style/StringLiteralsInInterpolation`
- resolved cookstyle error: attributes/iptables.rb:9:65 refactor: `ChefStyle/AttributeKeys`
- resolved cookstyle error: attributes/iptables.rb:9:66 convention: `Style/StringLiteralsInInterpolation`
- resolved cookstyle error: attributes/iptables.rb:10:55 refactor: `ChefStyle/AttributeKeys`
- resolved cookstyle error: attributes/iptables.rb:10:55 convention: `Style/StringLiteralsInInterpolation`
- resolved cookstyle error: attributes/iptables.rb:10:64 refactor: `ChefStyle/AttributeKeys`
- resolved cookstyle error: attributes/iptables.rb:10:65 convention: `Style/StringLiteralsInInterpolation`

## 2.7.0 (2018-12-19)

- Nominal support for Debian 9 (#202)

## 2.6.5 (2018-07-24)

- use platform_family instead of platform to include all rhels

## v2.6.4 (2018-07-01)

- Stop including chef-sugar when it's >= 4.0.0 (#197)

## v2.6.3 (2018-02-01)

- Fix issue with deep merging of hashes and arrays in recent chef release (#185)

## v2.6.2 (2017-06-01)

- Incorrect file checking on Ubuntu, double file write (#173)
- Added testing on CentOS 6.9
- Clarify metadata that we're not working on Amazon Linux (#172)

## v2.6.1 (2017-04-21)

- Add recipe to disable firewall (#164)

## v2.6.0 (2017-04-17)

- Initial Chef 13.x support (#160, #159)
- Allow loopback and icmp, when enabled (#161)
- Address various newer rubocop and foodcritic complaints
- Convert rule provider away from DSL (#159)

## v2.5.4 (2017-02-13)

- Update Test Kitchen platforms to the latest
- Update copyright headers
- Allow package options to be passed through to the package install for firewall
- Define policy for Windows Firewall and use the attributes to set desired policy

## v2.5.3 (2016-10-26)

- Don't show firewall resource as updated (#133)
- Add :off as a valid logging level (#129)
- Add support for Ubuntu 16.04 (#149)

## v2.5.2 (2016-06-02)

- Don't issue commands when firewalld isn't active (#140)
- Install iptables-services on CentOS >= 7 (#131)
- Update Ruby version on Travis for listen gem

## v2.5.1 (2016-05-31)

- Protocol guard incorrectly prevents "none" protocol type on UFW helper (#128)
- Fix wrongly ordered conditional for converting ports to strings using port_to_s
- Fix notify_firewall attribute crashing firewall_rule provider (#130)
- Add warning if firewall rule opens all traffic (#132)
- Add ipv6 attribute respect to Ubuntu iptables (#138)

## v2.5.0 (2016-03-08)

- Don't modify parameter for port (#120)
- Remove a reference to the wrong variable name under windows (#123)
- Add support for mobile shell default firewall rule (#121)
- New rubocop rules and style fixes
- Correct a README.md example for `action :allow`

## v2.4.0 (2016-01-28)

- Expose default iptables ruleset so that raw rules can be used in conjunction with rulesets for other tables (#101).

## v2.3.1 (2016-01-08)

- Add raw rule support to the ufw firewall provider (#113).

## v2.3.0 (2015-12-23)

- Refactor logic so that firewall rules don't add a string rule to the firewall when their actions run. Just run the action once on the firewall itself. This is designed to prevent partial application of rules (#106)

- Switch to "enabled" (positive logic) instead of "disabled" (negative logic) on the firewall resource. It was difficult to reason with "disabled false" for some complicated recipes using firewall downstream. `disabled` is now deprecated.

- Add proper Windows testing and serverspec tests back into this cookbook.

- Fix the `port_to_s` function so it also works for Windows (#111)

- Fix typo checking action instead of command in iptables helper (#112)

- Remove testing ranges of ports on CentOS 5.x, as it's broken there.

## v2.2.0 (2015-11-02)

Added permanent as default option for RHEL 7 based systems using firewall-cmd.
This defaults to turned off, but it will be enabled by default on the next major version bump.

## v2.1.0 (2015-10-15)

Minor feature release.

- Ensure ICMPv6 is open when `['firewall']['allow_established']` is set to true (the default). ICMPv6 is critical for most IPv6 operations.

## v2.0.5 (2015-10-05)

Minor bugfix release.

- Ensure provider filtering always yields 1 and only 1 provider, #97 & #98
- Documentation update #96

## v2.0.4 (2015-09-23)

Minor bugfix release.

- Allow override of filter chain policies, #94
- Fix foodcrtitic and chefspec errors

## v2.0.3 (2015-09-14)

Minor bugfix release.

- Fix wrong conditional for firewalld ports, #93
- Fix ipv6 command logic under iptables, #91

## v2.0.2 (2015-09-08)

- Release with working CI, Chefspec matchers.

## v2.0.1 (2015-09-01)

- Add default related/established rule for iptables

## v2.0.0 (2015-08-31)

- 84, major rewrite
   - Allow relative positioning of rules
   - Use delayed notifications to create one firewall ruleset instead of incremental changes
   - Remove poise dependency
- #82 - Introduce Windows firewall support and test-kitchen platform
- #73 - Add the option to disable ipv6 commands on iptables
- #78 - Use Chef-12 style `provides` to address provider mapping issues
- Rubocop and foodcritic cleanup

## v1.6.1 (2015-07-24)

- 80 - Remove an extra space in port range

## v1.6.0 (2015-07-15)

- 68 - Install firewalld when it does not exist
- 72 - Fix symbol that was a string, breaking comparisons

## v1.5.2 (2015-07-15)

- 75 - Use correct service in iptables save action, Add serverspec tests for iptables suite

## v1.5.1 (2015-07-13)

- 74 - add :save matcher for Chefspec

## v1.5.0 (2015-07-06)

- 70 - Add chef service resource to ensure firewall-related services are enabled/disabled
   - Add testing and support for iptables on ubuntu in iptables provider

## v1.4.0 (2015-06-30)

- 69 - Support for CentOS/RHEL 5.x

## v1.3.0 (2015-06-09)

- 63 - Add support for protocol numbers

## v1.2.0 (2015-05-28)

- 64 - Support the newer version of poise

## v1.1.2 (2015-05-19)

- 60 - Always add /32 or /128 to ipv4 or ipv6 addresses, respectively
      - Make comment quoting optional; iptables on Ubuntu strips quotes on strings without any spaces

## v1.1.1 (2015-05-11)

- 57 - Suppress warning: already initialized constant XXX while Chefspec

## v1.1.0 (2015-04-27)

- 56 - Better ipv6 support for firewalld and iptables
- 54 - Document raw parameter

## v1.0.2 (2015-04-03)

- 52 - Typo in :masquerade action name

## v1.0.1 (2015-03-28)

- 49 - Fix position attribute of firewall_rule providers to be correctly used as a string in commands

## v1.0.0 (2015-03-25)

- Major upgrade and rewrite as HWRP using poise
- Adds support for iptables and firewalld
- Modernize tests and other files
- Fix many bugs from ufw defaults to multiport suppot

## v0.11.8 (2014-05-20)

- Corrects issue where on a secondary converge would not distinguish between inbound and outbound rules

## v0.11.6 (2014-02-28)

[COOK-4385] - UFW provider is broken

## v0.11.4 (2014-02-25)

[COOK-4140] Only notify when a rule is actually added

## v0.11.2

### Bug

- [COOK-3615]: Install required UFW package on Debian

## v0.11.0

### Improvement

- [COOK-2932]: ufw providers work on debian but cannot be used

## v0.10.2

- [COOK-2250] - improve readme

## v0.10.0

- [COOK-1234] - allow multiple ports per rule

## v0.9.2

- [COOK-1615] - Firewall example docs have incorrect direction syntax

## v0.9.0

The default action for firewall LWRP is now :enable, the default action for firewall_rule LWRP is now :reject. This is in line with a "default deny" policy.

- [COOK-1429] - resolve foodcritic warnings

## v0.8.0

- refactor all resources and providers into LWRPs
- removed :reset action from firewall resource (couldn't find a good way to make it idempotent)
- removed :logging action from firewall resource...just set desired level via the log_level attribute

## v0.6.0

- [COOK-725] Firewall cookbook firewall_rule LWRP needs to support logging attribute.
- Firewall cookbook firewall LWRP needs to support :logging

## v0.5.7

- [COOK-696] Firewall cookbook firewall_rule LWRP needs to support interface
- [COOK-697] Firewall cookbook firewall_rule LWRP needs to support the direction for the rules

## v0.5.6

- [COOK-695] Firewall cookbook firewall_rule LWRP needs to support destination port

## v0.5.5

- [COOK-709] fixed :nothing action for the 'firewall_rule' resource.

## v0.5.4

- [COOK-694] added :reject action to the 'firewall_rule' resource.

## v0.5.3

- [COOK-698] added :reset action to the 'firewall' resource.

## v0.5.2

- Add missing 'requires' statements. fixes 'NameError: uninitialized constant' error. Thanks to Ernad Husremović for the fix.

## v0.5.0

- [COOK-686] create firewall and firewall_rule resources
- [COOK-687] create UFW providers for all resources
