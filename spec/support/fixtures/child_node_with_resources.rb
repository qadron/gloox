require 'gloox'

class MyNodeWithResources < Tiq::Node
    Slotz::Reservation.provision(
      self,
      disk:   1 * 1_000_000_000, # bytes
      memory: 1 * 1_000_000_000 # bytes
    )
end

return unless $execute

my_node = MyNodeWithResources.new( url: $options[:url] ).server.start
