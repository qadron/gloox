require 'gloox'

class MyAgent < GlooX::Agent
    Slotz::Reservation.provision(
      self,
      disk:   1 * 1_000_000_000, # bytes
      memory: 5 * 1_000_000_000 #
    )
end

return unless $execute

my_node = MyAgent.new( url: $options[:url] ).start

# Keep the process alive until killed by signal
trap('INT') { exit }
trap('TERM') { exit }
sleep 5
