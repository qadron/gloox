# GlooX (pronounced _glue-X_)

Bringing [Qadron](https://github.com/qadron) together, as a very special glue.

## Concepts

### Agent

`GlooX::Agent` offers _Agent_ representations, _server-side_ presences if you must,
of armed `Tiq::Nodes`.

They allow for spawning/loading of Processes on remote Nodes, with auto load-balancing
across their Grid.

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

```ruby
p $options
class Child
    Slotz::Reservation.provision( self,
        disk:   1 * 1_000_000_000, # bytes
        memory: 20 * 1_000_000_000 # bytes
)
end
```
