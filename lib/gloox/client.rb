require 'tiq'

module GlooX
class Client < Tiq::Client
    attr_reader :url

    def initialize( options = {} )
        options = options.symbolize_keys
        @url = options[:url]
        super( options[:url], options )
    end

end
end
