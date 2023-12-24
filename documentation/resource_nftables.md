# nftables

## Actions

- `:install`
- `:rebuild`
- `:restart`
- `:disable`

## Properties

| Name           | Type               | Default  | Description                                                      |
| -------------- | ------------------ | -------- | ---------------------------------------------------------------- |
| rules          | Hash               | {}       | Rules are accumulated in here. Key is a rule, value its priority |
| input_policy   | ['drop', 'accept'] | 'accept' | Policy for the input chain                                       |
| output_policy  | ['drop', 'accept'] | 'accept' | Policy for the output chain                                      |
| forward_policy | ['drop', 'accept'] | 'accept' | Policy for the forward chain                                     |
| table_ip_nat   | [true, false]      | false    | Create ip nat table, containing pre- and postrouting chains      |
| table_ip6_nat  | [true, false]      | false    | Create ip6 nat table, containing pre- and postrouting chains     |

## Examples

nftables is much more flexible than iptables, although it also uses the netfilter framework.
The nftables resource will setup nftables to be as similiar to iptables as possible, so by default
the following resource results in the following nftables ruleset:

```ruby
nftables 'default'
```

```nftables
table inet filter {
        chain INPUT {
                type filter hook input priority filter; policy accept;
        }

        chain OUTPUT {
                type filter hook output priority filter; policy accept;
        }

        chain FORWARD {
                type filter hook forward priority filter; policy accept;
        }
}
```

In order to get pre- and postrouting chains, and a more sensible policy for the chains, do the following:

```ruby
nftables 'default' do
  input_policy 'drop'
  table_ip_nat true
  table_ip6_nat true
end
```

This will result in the following ruleset:

```nftables
table inet filter {
        chain INPUT {
                type filter hook input priority filter; policy accept;
        }

        chain OUTPUT {
                type filter hook output priority filter; policy accept;
        }

        chain FORWARD {
                type filter hook forward priority filter; policy accept;
        }
}

table ip6 nat {
        chain PREROUTING {
                type nat hook prerouting priority -100 ; policy accept;
        }
        chain POSTROUTING {
                type nat hook prerouting priority 100 ; policy accept;
        }
}

table ip nat {
        chain PREROUTING {
                type nat hook prerouting priority -100 ; policy accept;
        }
        chain POSTROUTING {
                type nat hook prerouting priority 100 ; policy accept;
        }

}
```
