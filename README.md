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

# Setup a Grid of 2, the children will load-balance and connect to the most available node.
node = GlooX::Node.new( url: '0.0.0.0:9997' )
node.start

node2 = GlooX::Node.new( url: '0.0.0.0:9999', peer: '0.0.0.0:9997' )
node2.start

# Switchover to network communication over RPC.
c = GlooX::Client.new( url: node2.url )

c.spawn(
  'Child',
  "#{File.dirname(__FILE__)}/child.rb",
  { url: '0.0.0.0:8888', parent_url: '0.0.0.0:9999', daemonize: true }
)

# Setup the client-side child communication over RPC.
child_client = GlooX::Client.new( url: '0.0.0.0:8888' )

# Call the child-implemented method over RPC.
p child_client.all_well?
# => :yes!
```

`child.rb:`
```ruby
require 'gloox'

p $options
# => {:url=>"localhost:8888", :parent_url=>"localhost:9999", :ppid=>846068, :tmpdir=>"/tmp", :execute=>true}

class Child < GlooX::Node
    Slotz::Reservation.provision(
      self,
      disk:   1 * 1_000_000_000, # bytes
      memory: 1 * 1_000_000_000 # bytes
    )

    def all_well?
        :yes!
    end
end

# Time to execute, sniff was taken care of on prior file inclusion.
return unless $execute

# Start the child-node server, not included in the Grid, only given its own bind URL.
c = Child.new( url: $options[:url] )
c.start

# Setup communication to the parent.
parent = GlooX::Client.new( url: $options[:parent_url] )

p parent.alive?
# => true
```

### Add-ons

For the _Add-on_ feature see [Tiq](https://github.com/qadron/tiq?tab=readme-ov-file#add-ons).

### Groups/Channels

You can group and/or assign duty/purpose to your _Agents_ by creating channels/shared structures across them.

There is one such example below, where two Agents share a group named `my_agents`, in addition to the group `channel`, 
used for initial/internal purposes.

```ruby
require 'gloox'

n1 = GlooX::Node.new( url: "0.0.0.0:9999" ).start
n2 = GlooX::Node.new( url: "0.0.0.0:9998", peer: '0.0.0.0:9999' ).start

# Add as many groups/channels/shared-data structures as you want.
n1.create_channel 'my_nodes'
sleep 1

n2.my_nodes.on_set :a1 do |k, v|
    p "#{k} => #{v}"
    # => "a1 => 99"
end

n1.my_nodes.set :a1, 99
sleep 1

p n2.my_nodes.get :a1
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
