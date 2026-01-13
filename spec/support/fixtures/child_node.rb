require 'gloox'

class MyNode < GlooX::Node
end

return unless $execute

my_node = MyNode.new( url: $options[:url] ).start
