require 'tiq'

module GlooX
class Client < Tiq::Client
    attr_reader :url

    def initialize( options = {} )
        super( options[:url], options )
    end

end
end
