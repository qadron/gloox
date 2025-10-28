require 'gloox'
class MyNode < Tiq::Node
end
exit if $options.nil?

my_node = MyNode( url: $options[:url] ).start
