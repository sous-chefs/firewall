# Firewall cookbook migration

## Scope and compatibility

* Full custom resource migration and a major release are authorised. Remove root
  recipes, attributes and the legacy Chef resource/provider class hierarchy.
* This is `sous-chefs/firewall`, distinct from `sous-chefs/firewalld`. Preserve
  this repository's Supermarket and OCI publication settings.
* Retain public firewall, firewall_rule, nftables and firewalld D-Bus resources.
  Replace node attributes with explicit resource properties. Preserve default
  routing: Debian uses UFW; Amazon, Fedora, RHEL and SUSE use firewalld; Windows
  uses native Windows Firewall; other platforms use iptables.
* The generic firewalld backend in this repository uses D-Bus rich rules,
  including zone and port arrays. Do not substitute the extraction's older
  direct-rule implementation. Retain zone ingress/egress/combined priorities and
  the standalone firewalld_rich_rule public API.
* Reuse applicable common helper/backend fixes from firewalld PR18, with review
  against this repository's APIs. Do not copy its reduced supported-platform
  list or OCI-only release settings.

## Product requirements

Linux packages are distribution builds of UFW, iptables, nftables and firewalld;
there is no source build or vendor repository. Windows Firewall is built into
supported Windows releases. Linux requires systemd and kernel Netfilter support;
tests need NET_ADMIN in isolated privileged containers or disposable VMs.
Never use host networking or run disable/flush/delete tests on the workstation.

* [Ubuntu firewall and package baselines](https://documentation.ubuntu.com/security/security-features/network/firewall/)
* [Netfilter documentation](https://netfilter.org/documentation/)
* [nftables manual](https://netfilter.org/projects/nftables/manpage.html)
* [firewalld D-Bus API](https://firewalld.org/documentation/man-pages/firewalld.dbus.html)
* [firewalld rich-rule syntax](https://firewalld.org/documentation/man-pages/firewalld.richlanguage.html)

Ubuntu 20.04 remains an ESM option by owner decision. Retire obsolete CI versions
while retaining supported platform families and native Windows coverage. Actual
backend/package availability determines each platform's integration suites.

## Acceptance

All public resources need step-into coverage. Exercise actual Linux rule creation,
repeat convergence, deletion and persisted-rule removal in isolation. Retain
numeric protocols, IPv4/IPv6, NAT, UFW raw rules, named-firewall association,
firewalld zone/array rules and D-Bus optional false values. Windows requires a
native runner; Linux success does not prove Windows behaviour.

Keep generated release PR337 untouched until a reviewed breaking feature merges
and release-please regenerates cookbook8.0.0. Merge only reviewed green heads
under the current owner authorisation, then verify tag/metadata agreement and
the actual OCI publisher job.

## Verified runtime findings

* Reused common migration work from the distinct firewalld PR18, including its
  verified readiness/dependency patch ad87435. Fedora45 firewalld2.5.2 uses a
  Type=simple unit, so systemd start can return before the D-Bus name is owned.
  A guarded, retried state probe preserves repeat-converge idempotency.
* DNF removal disables automatic dependency cleanup so removing firewalld does
  not also remove shared ipset dependencies or run their kernel-module PREUN
  scripts. Other packages are not owned by the firewalld resource.
* Advanced fixtures explicitly manage home-zone services. Factory samba-client
  defaults can require a netbios conntrack helper absent from Docker kernels;
  this is test setup, not a production backend workaround.
* Minimal images may render IP protocol112 numerically instead of as vrrp. Tests
  accept either spelling and still require the actual protocol constraint.
* Local actionlint1.7.12 combined external-check mode spun at100%CPU. Native
  actionlint validation with external tools disabled and independent ShellCheck
  validation of every Bash run block both pass. CI remains fully enabled.

## Local acceptance evidence

* All 73 ChefSpec examples pass, including every public resource and shared
  helper, numeric protocols, named rule registration, NAT and D-Bus flags.
* Debian 13 generic firewalld: 19 assertions; advanced D-Bus: 48; iptables: 31;
  nftables: 30. Ubuntu 20 ESM UFW: 15. All second converges updated zero resources.
  Fedora 45 advanced D-Bus also passed 48, with second converge 0/51 after the
  evidence-backed readiness probe.
* Lifecycle checks passed: NAT removal 4, custom mangle policy 4, disable/reset 8,
  iptables deletion 3, UFW deletion 2, nftables deletion 2, D-Bus object deletion
  21 and generic firewalld deletion 1. Repeated deletion converges made zero
  changes. All data and rules were synthetic and isolated.
* Current firewalld servers add a policy CLI `disable: no` field. Profiles detect
  its advertised presence and require the safe default while checking the same
  managed policy values; no runtime property is silently introduced.

Independent review of the initial feature head found that the Windows outbound
renderer ignored the `port` shorthand and emitted `remoteport=any`. Correct it
with the existing destination-port helper; test single ports, ranges and arrays
both in ChefSpec and against actual native Windows rule output. Review otherwise
confirmed the D-Bus bridge/zone/lifecycle contract. Package removal may retain
permanent XML; explicit object resources own removal of that state.

Hosted Ubuntu20 ESM uses legacy ip6tables, whose container cannot load the host's
ip6_tables module from its empty module directory. Initial CI job131186271128
failed at ufw logging with that exact kernel error. Preload the legacy firewall
modules on the ephemeral CI VM for Ubuntu20 jobs; keep production backend and
IPv6 behaviour unchanged. This matches the independently diagnosed legacy
Fedora container fixture requirement in the separate firewalld project.

Native Windows job131186269688 rejected default port fields for protocol112.
Only TCP/UDP (including numeric6/17) now emit port fields; incompatible explicit
port restrictions fail before apply. Existing protocol aliases use netsh names
or IP protocol numbers. ChefSpec covers aliases, numeric protocols and rejection;
native fixtures check protocol112 plus numeric TCP/UDP ports.
