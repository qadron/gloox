# coding: utf-8

Gem::Specification.new do |s|
    require_relative File.expand_path( File.dirname( __FILE__ ) ) + '/lib/gloox/version'

    s.name              = 'gloox'
    s.version           = GlooX::VERSION
    s.date              = Time.now.strftime( '%Y-%m-%d' )
    s.summary           = ''

    s.homepage          = 'https://github.com/qadron/gloox'
    s.email             = 'tasos.laskos@gmail.com'
    s.authors           = [ 'Tasos Laskos' ]
    s.licenses          = ['MPL v2']

    s.files            += Dir.glob( 'config/**/**' )
    s.files            += Dir.glob( 'lib/**/**' )
    s.files            += Dir.glob( 'logs/**/**' )
    s.files            += Dir.glob( 'components/**/**' )
    s.files            += Dir.glob( 'spec/**/**' )
    s.files            += %w(Gemfile gloox.gemspec)
    s.test_files        = Dir.glob( 'spec/**/**' )

    s.extra_rdoc_files  = %w(README.md LICENSE.md)

    s.rdoc_options      = [ '--charset=UTF-8' ]

    s.add_dependency 'awesome_print',       '1.9.2'
    s.add_dependency 'bundler'
    s.add_dependency 'msgpack'
    s.add_dependency 'slotz'
    s.add_dependency 'tiq'

    s.description = <<DESCRIPTION
DESCRIPTION

end
