require 'slotz'
require 'tiq'

module GlooX
class Node < Tiq::Node
    PREFERENCE_STRATEGIES = Set.new([nil, :horizontal, :vertical, :direct])

    def initialize(*)
        super

        @loader = Slotz::Loader.new
    end

    def spawn( *args, &block )
        probable_strategy = args.shift
        strategy = probable_strategy.to_s.to_sym

        if PREFERENCE_STRATEGIES.include? strategy
            spawn2( strategy, *args, &block )
        else
            args.unshift probable_strategy
            spawn2( nil, *args, &block )
        end

        nil
    end

    def utilization
        Slotz.utilization
    end

    def preferred( strategy = nil, &block )
        strategy = (strategy || :vertical).to_sym
        if !PREFERENCE_STRATEGIES.include? strategy
            block.call :error_unknown_strategy
            raise ArgumentError, "Unknown strategy: #{strategy}"
        end

        if strategy == :direct || !grid_member?
            block.call( self.utilization >= 1.0 ? nil : @url )
            return
        end

        pick_utilization = proc do |url, utilization|
            (utilization == 1 || utilization.rpc_exception?) ?
              nil : [url, utilization]
        end

        adjust_score_by_strategy = proc do |score|
            case strategy
                when :horizontal
                    score

                when :vertical
                    -score
            end
        end

        each = proc do |peer, iter|
            connect_to_peer( peer ).utilization do |utilization|
                iter.return pick_utilization.call( peer, utilization )
            end
        end

        after = proc do |nodes|
            nodes << pick_utilization.call( @url, self.utilization )
            nodes.compact!

            # All nodes are at max utilization, pass.
            if nodes.empty?
                block.call
                next
            end

            block.call nodes.sort_by { |_, score| adjust_score_by_strategy.call score }[0][0]
        end

        @reactor.create_iterator( @peers ).map( each, after )
        nil
    end

    private


    def spawn2( strategy = nil, *args, &block )
        if !grid_member?
            pid = self.load_spawn( *args )

            if block_given?
                block.call pid
                return
            end
            return pid
        end

        preferred strategy do |preferred_url|
            if preferred_url.nil?
                next
            end

            if preferred_url == @url
                pid = self.load_spawn( *args )
                block.call pid if block_given?
            else
                connect_to_peer( preferred_url ).spawn( :direct, *args, &block )
            end
        end

        nil
    rescue => e
        p e
    end

    def load_spawn( klass, executable, options = {} )
        # Check if file fits into available resources before loading
        requirements = peek_file_requirements( executable )
        if requirements && !fits_available_resources?( requirements )
            raise Slotz::InsufficientResourcesError,
                  "Insufficient resources to spawn #{klass}. " \
                  "Required: #{requirements}, Available: #{available_resources}"
        end

        @loader.load( klass, executable, options.merge( node_url: self.url ) )
    end

    # Peek into the file to extract resource requirements
    def peek_file_requirements( executable )
        return nil unless File.exist?( executable )

        content = File.read( executable )
        
        # Look for Slotz::Reservation.provision calls
        # Example: Slotz::Reservation.provision(self, disk: 1000, memory: 2000)
        match = content.match(/Slotz::Reservation\.provision\s*\(\s*[^,]+,\s*([^)]+)\)/)
        return nil unless match

        # Parse the requirements hash
        requirements_str = match[1]
        requirements = {}
        
        # Extract disk requirement
        if disk_match = requirements_str.match(/disk:\s*(\d+(?:\s*\*\s*\d+)*)/)
            requirements[:disk] = eval(disk_match[1])
        end
        
        # Extract memory requirement
        if memory_match = requirements_str.match(/memory:\s*(\d+(?:\s*\*\s*\d+)*)/)
            requirements[:memory] = eval(memory_match[1])
        end
        
        requirements.empty? ? nil : requirements
    end

    # Check if requirements fit into available resources
    def fits_available_resources?( requirements )
        available = available_resources
        
        return false if requirements[:disk] && requirements[:disk] > available[:disk]
        return false if requirements[:memory] && requirements[:memory] > available[:memory]
        
        true
    end

    # Get available system resources
    def available_resources
        {
            disk: Slotz.available_disk,
            memory: Slotz.available_memory
        }
    end
end
end
