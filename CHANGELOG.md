## v0.10.2:

* [COOK-2250] - improve readme

## v0.10.0:

* [COOK-1234] - allow multiple ports per rule

## v0.9.2:

* [COOK-1615] - Firewall example docs have incorrect direction syntax

## v0.9.0:

The default action for firewall LWRP is now :enable, the default
action for firewall_rule LWRP is now :reject. This is in line with a
"default deny" policy.

* [COOK-1429] - resolve foodcritic warnings

## v0.8.0:

* refactor all resources and providers into LWRPs
* removed :reset action from firewall resource (couldn't find a good way to make it idempotent)
* removed :logging action from firewall resource...just set desired level via the log_level attribute

## v0.6.0:

* [COOK-725] Firewall cookbook firewall_rule LWRP needs to support logging attribute.
* Firewall cookbook firewall LWRP needs to support :logging

## v0.5.7:

* [COOK-696] Firewall cookbook firewall_rule LWRP needs to support interface
* [COOK-697] Firewall cookbook firewall_rule LWRP needs to support the direction for the rules

## v0.5.6:

* [COOK-695] Firewall cookbook firewall_rule LWRP needs to support destination port

## v0.5.5:

* [COOK-709] fixed :nothing action for the 'firewall_rule' resource.

## v0.5.4:

* [COOK-694] added :reject action to the 'firewall_rule' resource.

## v0.5.3:

* [COOK-698] added :reset action to the 'firewall' resource.

## v0.5.2:

* add missing 'requires' statements. fixes 'NameError: uninitialized constant' error.
thanks to Ernad Husremović for the fix.

## v0.5.0:

* [COOK-686] create firewall and firewall_rule resources
* [COOK-687] create UFW providers for all resources
