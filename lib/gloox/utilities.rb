module Gloox
module Utilities

    def self.available_port_mutex
        @available_port_mutex ||= Mutex.new
    end
    available_port_mutex

    def available_port( range = nil )
        Gloox::Utilities.available_port_mutex.synchronize do
            loop do
                port = self.random_port( range )
                return port if port_available?( port )
            end
        end
    end

    def random_port( range = nil )
        range ||= [1025, 65535]
        first, last = range
        range = (first..last).to_a

        range[ rand( range.last - range.first ) ]
    end

end
end

