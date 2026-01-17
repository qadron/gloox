require 'slotz'
require 'slotz/loader'
require 'tiq'

module GlooX
class Agent < Tiq::Node
    PREFERENCE_STRATEGIES = Set.new([nil, :horizontal, :vertical, :direct])

    attr_accessor :weight

    def initialize(*);
        super;

        @loader = ::Slotz::Loader.new
        @weight = 1.0
    end

    def spawn( klass, path, options = {}, strategy = nil, &block )
        strategy = strategy.to_s.to_sym if strategy

        if !PREFERENCE_STRATEGIES.include? strategy
            block.call :error_unknown_strategy
            raise ArgumentError, "Unknown strategy: \\\#{strategy}"
        end

        if !grid_member?
            pid = self.load_spawn( klass, path, options )

            if block_given?
                block.call pid
                return
            end
            return pid
        end

        preferred klass, path, strategy do |preferred_url|
            if preferred_url.nil?
                next
            end

            if preferred_url == @url
                pid = self.load_spawn( klass, path, options )
                block.call pid if block_given?
            else
                connect_to_peer( preferred_url ).spawn( :direct, klass, path, options, &block )
            end
        end

        nil
    end

    def utilization
        Slotz.utilization
    end

    def fits?( klass, path, &block )
        require_relative path
        c = Object.const_get( klass )
        c = c.allocate

        if c.respond_to? :available_slots
            if c.available_slots >= 1
                block.call true if block
                return true
            else
                block.call false if block
                return false
            end
        else
            block.call nil if block
            return nil
        end

        nil
    end

    def preferred( klass, path, strategy = nil, &block )
        strategy = (strategy || :vertical).to_sym
        if !PREFERENCE_STRATEGIES.include? strategy
            block.call :error_unknown_strategy
            raise ArgumentError, "Unknown strategy: \\\#{strategy}"
        end

        if strategy == :direct || !grid_member?
            fit = fits?( klass, path )

            if fit.nil?
                block.call( self.utilization < 1 ? @url : nil )
            else
                if fit
                    block.call( @url )
                else
                    block.call nil
                end
            end

            return
        end

        pick_utilization = proc do |url, utilization, weight|
            (utilization >= 1 || utilization.rpc_exception?) ?
              nil : [url, utilization, weight]
        end

        adjust_score_by_strategy = proc do |utilization, weight|
            score = utilization * weight
            case strategy
                when :horizontal
                    score

                when :vertical
                    -score
            end
        end

        each = proc do |peer, iter|
            connect_to_peer( peer ).fits?( klass, path ) do |fit, utilization|
                if fit.nil? || fit
                    connect_to_peer( peer ).weight do |weight|
                        iter.return pick_utilization.call( peer, utilization, weight )
                    end
                else
                    iter.return
                end
            end
        end

        after = proc do |nodes|
            fits = fits?( klass, path )
            if fits.nil? || fits
                nodes << pick_utilization.call( @url, self.utilization, @weight )
            end
            nodes.compact!

            # All nodes are at max utilization, pass.
            if nodes.empty?
                block.call
                next
            end

            block.call nodes.sort_by { |_, utilization, weight| 
                adjust_score_by_strategy.call(utilization, weight) 
            }[0][0]
        end

        @reactor.create_iterator( @peers ).map( each, after )
        nil
    end

    private


    def load_spawn( klass, executable, options = {} )
        @loader.load( klass, executable, options.merge( node_url: self.url ) )
    end
end
end
