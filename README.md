# GlooX (pronounced _glue-X_)

GlooX

```ruby
require 'gloox'

agent = GlooX::Agent.new( url: 'localhost:9997' ).start
agent2 = GlooX::Agent.new( url: 'localhost:9999', peer: 'localhost:9997' ).start

c = Tiq::Client.new( agent2.url )

p c.spawn(
  'Child',
  "#{File.dirname(__FILE__)}/test/child.rb",
  { e: 27 }
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
