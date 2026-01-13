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

    def preferred( strategy = nil, required_resources = nil, &block )
        strategy = (strategy || :vertical).to_sym
        if !PREFERENCE_STRATEGIES.include? strategy
            block.call :error_unknown_strategy
            raise ArgumentError, "Unknown strategy: #{strategy}"
        end

        if strategy == :direct || !grid_member?
            # Check if local node has sufficient resources
            if required_resources && !fits_available_resources?( required_resources )
                block.call( nil )
            else
                block.call( self.utilization >= 1.0 ? nil : @url )
            end
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

            # Filter out nodes that don't have sufficient resources
            if required_resources
                nodes.select! do |url, _|
                    if url == @url
                        fits_available_resources?( required_resources )
                    else
                        # Check remote node's available resources
                        begin
                            remote_available = connect_to_peer( url ).available_resources
                            remote_available[:disk] >= (required_resources[:disk] || 0) &&
                              remote_available[:memory] >= (required_resources[:memory] || 0)
                        rescue
                            # If we can't check remote resources, exclude the node
                            false
                        end
                    end
                end
            end

            # All nodes are at max utilization or lack resources, pass.
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
        # Extract resource requirements from the file before selecting a node
        klass, executable, options = args
        required_resources = peek_file_requirements( executable )

        if !grid_member?
            # Check if local node has sufficient resources
            if required_resources && !fits_available_resources?( required_resources )
                raise Slotz::InsufficientResourcesError,
                      "Insufficient resources to spawn #{klass}. " \
                      "Required: #{required_resources}, Available: #{available_resources}"
            end

            pid = self.load_spawn( *args )

            if block_given?
                block.call pid
                return
            end
            return pid
        end

        preferred strategy, required_resources do |preferred_url|
            if preferred_url.nil?
                # No node with sufficient resources available
                if block_given?
                    block.call nil
                end
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
        # Resource checking is done in spawn2 before node selection
        # This ensures only nodes with sufficient resources are considered
        @loader.load( klass, executable, options.merge( node_url: self.url ) )
    end

    # Peek into the file to extract resource requirements
    def peek_file_requirements( executable )
        return nil unless File.exist?( executable )

        content = File.read( executable )
        
        # Look for Slotz::Reservation.provision calls (may be multi-line)
        # Example: Slotz::Reservation.provision(self, disk: 1000, memory: 2000)
        match = content.match(/Slotz::Reservation\.provision\s*\(\s*[^,]+,\s*([^)]+)\)/m)
        return nil unless match

        # Parse the requirements hash
        requirements_str = match[1]
        requirements = {}
        
        # Extract disk requirement - matches numbers, underscores, spaces, and * operator
        if disk_match = requirements_str.match(/disk:\s*([\d_\s*]+)/)
            requirements[:disk] = calculate_value(disk_match[1])
        end
        
        # Extract memory requirement - matches numbers, underscores, spaces, and * operator
        if memory_match = requirements_str.match(/memory:\s*([\d_\s*]+)/)
            requirements[:memory] = calculate_value(memory_match[1])
        end
        
        requirements.empty? ? nil : requirements
    end

    # Safely calculate numeric expressions (e.g., "1 * 1_000_000_000")
    # Only supports simple multiplication of positive integers
    def calculate_value( expression )
        # Remove spaces and underscores for parsing
        cleaned = expression.gsub(/[\s_]/, '')
        
        # Support simple multiplication expressions like "1*1000000000"
        if cleaned.include?('*')
            parts = cleaned.split('*').map(&:to_i)
            # Validate all parts are positive
            return 0 if parts.any? { |p| p <= 0 }
            parts.reduce(:*)
        else
            cleaned.to_i
        end
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
