=begin

    This file is part of the gloox project and may be subject to
    redistribution and commercial restrictions. Please see the gloox
    web site for more information on licensing and terms of use.

=end

require 'rubygems'
require File.expand_path( File.dirname( __FILE__ ) ) + '/lib/gloox/version'

begin
    require 'rspec'
    require 'rspec/core/rake_task'

    RSpec::Core::RakeTask.new
rescue
end

task default: [ :build, :spec ]

desc 'Generate docs'
task :docs do
    outdir = "../gloox"
    sh "rm -rf #{outdir}"
    sh "mkdir -p #{outdir}"

    sh "yardoc -o #{outdir}"

    sh "rm -rf .yardoc"
end

desc 'Clean up'
task :clean do
    sh 'rm *.gem || true'
end

desc 'Build the gloox gem.'
task build: [ :clean ] do
    sh 'gem build gloox.gemspec'
end

desc 'Build and install the gloox gem.'
task install: [ :build ] do
    sh "gem install gloox-#{GlooX::VERSION}.gem"
end

desc 'Push a new version to Rubygems'
task publish: [ :build ] do
    sh "git tag -a v#{GlooX::VERSION} -m 'Version #{GlooX::VERSION}'"
    sh "gem push gloox-#{GlooX::VERSION}.gem"
end
task release: [ :publish ]
