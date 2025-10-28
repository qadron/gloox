require 'gloox'

class MyNode < Tiq::Node
end

return unless $execute

my_node = MyNode( url: $options[:url] ).start
