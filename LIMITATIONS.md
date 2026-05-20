# Limitations

## Platform Support

This cookbook manages firewall frontends that ship with operating system package
repositories. It does not add external package repositories.

### Linux

* Debian 12 and 13: `ufw`, `iptables`, `nftables`, and `firewalld` packages are available from Debian repositories. Debian recommends nftables as the default packet filtering framework, so the `firewall` resource defaults to `:nftables` on Debian.
* Ubuntu 22.04 and 24.04: `ufw`, `iptables`, `nftables`, and `firewalld` packages are available from Ubuntu repositories.
* RHEL-compatible platforms 8, 9, and 10: firewalld is the default supported frontend. iptables compatibility packages remain available, but Red Hat documents iptables-nft and ipset as deprecated in RHEL 9 and recommends nftables for direct ruleset management.
* Amazon Linux 2023: firewalld and iptables compatibility packages are available from the base repositories. UFW is not included in the base repositories.
* Fedora: firewalld is the default firewall frontend and uses nftables as its backend.

### Windows

Windows support uses the built-in Windows Firewall through `netsh advfirewall`.
The current support target is Windows Server 2022 or newer.

## Package Availability

| Platform family              | Primary backend   | Notes                                                         |
| ---------------------------- | ----------------- | ------------------------------------------------------------- |
| Debian                       | nftables          | Default selected by `firewall` on Debian 12 and 13.           |
| Ubuntu                       | UFW               | Preserves the legacy Ubuntu `firewall` resource default.      |
| RHEL/Fedora/Amazon/SUSE-like | firewalld         | UFW requires repositories outside some supported base images. |
| Windows                      | Windows Firewall  | Uses the built-in `MpsSvc` service and `netsh advfirewall`.   |

## Known Issues

* This cookbook does not configure external package repositories such as EPEL.
* UFW on RHEL-family systems depends on repository availability outside this cookbook.
* Linux container integration tests require privileged Dokken containers with systemd.
* Windows integration tests require a Windows runner and are not part of the Linux Dokken matrix.
