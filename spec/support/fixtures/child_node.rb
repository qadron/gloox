require 'gloox'

class MyNode < Tiq::Node
end

return unless $execute

my_node = MyNode.new( url: $options[:url] ).server.start
