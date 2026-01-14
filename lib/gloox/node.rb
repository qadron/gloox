require 'tiq/node'

module GlooX
class Node < Tiq::Node

    class <<self

        def when_ready( url, &block )
            client = GlooX::Client.new(
              url: url,
              client_max_retries: 0,
              connection_pool_size: 1,
              handler: :node )

            reactor = Raktr.new
            reactor.run_in_thread
            reactor.delay( 0.1 ) do |task|
                client.alive? do |r|
                    if r.rpc_exception?
                        reactor.delay( 0.1, &task )
                        next
                    end

                    client.close
                    reactor.stop
                    block.call
                end
            end
        end

        def connect( options = {} )
            GlooX::Client.new(
              options.merge( handler: :node )
            )
        end

        def boot( options = {} )
            connect( url: start( options ).url )
        end

        def start( options = {} )
            n = new( options )
            n.start
            n
        end
    end

    # No Instance fits here for spawning, so take us out of rotation.
    # We're here just to watch and do comms.
    def fits?(*)
        false
    end
end

end
