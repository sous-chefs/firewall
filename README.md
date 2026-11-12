# Firewall cookbook

Provides custom resources for UFW, iptables, firewalld, nftables and Windows
Firewall. Cookbook 8 removes the legacy recipes, attributes and provider classes.
See [MIGRATING.md](MIGRATING.md) before upgrading.

## Requirements

Chef/Cinc 18+ is the supported runtime baseline. Linux uses systemd and distribution
firewall packages; Windows uses its native firewall. Kernel Netfilter support is
required for Linux operations.

Supported platform families remain Amazon Linux, AlmaLinux, CentOS Stream,
Debian, Fedora, Oracle Linux, RHEL, Rocky Linux, SUSE and Ubuntu, plus Windows.
Ubuntu 20.04 is retained for ESM users. Current test versions and package-specific
suite restrictions are defined in the Kitchen files.

## Basic usage

Call resources from a wrapper cookbook:

```ruby
firewall 'default' do
  allow_ssh true
end

firewall_rule 'HTTPS' do
  port 443
  command :allow
end
```

The default backend remains UFW on Debian/Ubuntu; firewalld on Amazon Linux,
RHEL-family, Fedora and SUSE; Windows Firewall on Windows; iptables elsewhere.
Override it explicitly with `backend :iptables`, `:ufw`, `:firewalld` or
`:windows` on the `firewall` resource. nftables has separate resources.

Declare the named firewall before its rules. Select one host-wide backend:
multiple named resources do not create independent operating-system firewalls.
Allow management traffic before applying restrictive policies.

## Resources

* [firewall](documentation/firewall.md)
* [firewall_rule](documentation/firewall_rule.md)
* [nftables](documentation/resource_nftables.md)
* [nftables_rule](documentation/resource_nftables_rule.md)
* [firewalld D-Bus resources](documentation/README.md), including zones, policies,
  services, helpers, IP sets, ICMP types, configuration and rich rules.

The firewalld backend retains its D-Bus rich-rule implementation, including zone
selection, numeric protocols, port arrays and ranges. It does not use the separate
firewalld cookbook's legacy direct-rule backend.

## Testing and distribution

The Policyfile-backed test cookbook exercises actual rule application, a second
converge with no changes, and explicit removal. Linux tests run in isolated
privileged containers; Windows tests use a native runner. Never run lifecycle
tests on the workstation or a production firewall.

This repository publishes versioned cookbooks to Supermarket and GHCR.
