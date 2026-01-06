require 'tiq'

module GlooX
class Client < Tiq::Client
    attr_reader :url

    def initialize( options = {} )
        options = options.symbolize_keys
        super( options[:url], options )
    end

end
end
