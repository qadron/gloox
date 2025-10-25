source 'https://rubygems.org'

gem 'rake', '13.0.3'

group :docs do
    gem 'yard'
    gem 'redcarpet'
end

group :spec do
    gem 'rspec'
end

group :prof do
    gem 'benchmark-ips'
    gem 'memory_profiler'
end

if File.exist? '../toq'
    gem "toq", path: '../toq'
end

if File.exist? '../slotz'
    gem "slotz", path: '../slotz'
end

if File.exist? '../tiq'
    gem "tiq", path: '../tiq'
end

if File.exist? '../raktr'
    gem "raktr", path: '../raktr'
end

gem 'msgpack'

gemspec
