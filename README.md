# GlooX (pronounced _glue-X_)

**An effort to make distributed computing a joy!**

**Do you really need more, or could you do away with less?**

**Lean and mean never fails.**

**Introducing GlooX, your new "cloud" taming solution, under Mozilla Public License v2.**

_Bringing [Qadron](https://github.com/qadron) together, as a very special glue._

## Table of Contents

- [GlooX::Agent](#agents) `<` [Tiq::Node](https://github.com/qadron/tiq)
  - [Add-ons](#add-ons)
  - [Groups](#groups)
- [Provisioning](#provisioning)
- [Security](#security)

## Agents

`GlooX::Agent` offers _Agent_ representations, _server-side_ presences if you must,
of armed `Tiq::Node`s.

They allow for spawning/loading of Processes on remote Nodes, with auto load-balancing
across their Grid.

`demo.rb:`
```ruby
require 'gloox'

# Start off with two Agents, in a Grid of their own
agent  = GlooX::Agent.new( url: 'localhost:9997' ).start
agent2 = GlooX::Agent.new( url: 'localhost:9999', peer: 'localhost:9997' ).start

# Connect over the network for RPC.
c = Tiq::Client.new( agent2.url )

p c.spawn(
  'Child',
  "#{File.dirname(__FILE__)}/test/child.rb",
  { e: 27 } # Global options set for the spawned Child.
)

p c.utilization
# => 0.7281599728827168

p "--- #{c.preferred}"
#=> localhost:9997
```

`child.rb:`
```ruby
p $options
# => {:execute=>false}
# => {:e=>27, :ppid=>3164437, :tmpdir=>"/tmp", :execute=>true}

class Child
    Slotz::Reservation.provision( self,
        disk:   1 * 1_000_000_000, # bytes
        memory: 20 * 1_000_000_000 # bytes
)
end
```

### Add-ons

For the _Add-on_ feature see [Tiq](https://github.com/qadron/tiq?tab=readme-ov-file#add-ons).

### Groups/Channels

You can group and/or assign duty/purpose to your _Agents_ by creating channels/shared structures across them.

There is one such example below, where two Agents share a group named `my_agents`, in addition to the group `channel`, 
used for initial/internal purposes.

```ruby
require 'gloox'

n1 = GlooX::Agent.new( url: "localhost:9999" ).start
n2 = GlooX::Agent.new( url: "localhost:9998", peer: 'localhost:9999' ).start

# Add as many groups/channels/shared-data structures as you want.
n1.create_channel 'my_agents'
sleep 1

n2.my_agents.on_set :a1 do |k, v|
    p "#{k} => #{v}"
    # => "a1 => 99"
end

n1.my_agents.set :a1, 99
sleep 1

p n2.my_agents.get :a1
# => 99
```

## Provisioning

Due to the nature of distributed computing, resource management is key to a happy workflow.

With [Slotz](https://github.com/qadron/slotz), you can set your payloads'/classes' resource requirements (disk, memory)
beforehand and have your distributed application run smoothly within the Node that was selected automatically as its best home.

```ruby
require 'slotz'

class MyApp
    Slotz::Reservation.provision( self,
        disk:   1 * 1_000_000_000, # bytes
        memory: 20 * 1_000_000_000 # bytes
)
end
```

## Security

All communications are TLS encrypted by default, using [Raktr](https://github.com/qadron/raktr) to facilitate network
communications for RPC, with RPC being offered by [Toq](https://github.com/qadron/toq).

7 environment variables will have you sleeping safe and sound:

* Certificate Authority (`RAKTR_TLS_CA`)
* Server
  * Certificate (`RAKTR_TLS_SERVER_CERTIFICATE`)
  * Private Key (`RAKTR_TLS_SERVER_PRIVATE_KEY`)
  * Public Key (`RAKTR_TLS_SERVER_PUBLIC_KEY`)
* Client
  * Certificate (`RAKTR_TLS_CLIENT_CERTIFICATE`)
  * Private Key (`RAKTR_TLS_CLIENT_PRIVATE_KEY`)
  * Public Key (`RAKTR_TLS_CLIENT_PUBLIC_KEY`)

Helper:
https://raw.githubusercontent.com/qadron/raktr/refs/heads/master/spec/support/fixtures/pems/generate-tls-certs.sh
