require 'gloox'

class MyNode < Tiq::Node
end

exit if $slotz_load.nil?

my_node = MyNode( url: $options[:url] ).start
