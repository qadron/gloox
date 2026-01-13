require 'gloox'

class MyNode < GlooX::Node
end

return unless $execute

my_node = MyNode.new( url: $options[:url] ).start

# Keep the process alive until killed by signal
trap('INT') { exit }
trap('TERM') { exit }
sleep
