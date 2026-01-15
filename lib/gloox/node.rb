require 'tiq/node'

module GlooX
class Node < Tiq::Node


    class<<self
        def connect( options = {} )
            Tiq::Client.new( options.merge handler: :node )
        end
    end

    # No Instance fits here for spawning, so take us out of rotation.
    # We're here just to watch and do comms.
    def fits?(*)
        false
    end
end

end
