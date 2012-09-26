# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "spar/version"

Gem::Specification.new do |s|
  s.name        = "spar"
  s.version     = Spar::VERSION
  s.authors     = ["Matt Hodgson"]
  s.email       = ["matt@boundless.com"]
  s.homepage    = "http://boundlesslearning.github.com/spar"
  s.summary     = %q{A simple framework for developing single page web apps with support for haml, sass, coffeescript, and pretty much anything else.}
  s.description = %q{Spar uses Sprockets to provide an asset development environment very similar to the asset pipeline found in Rails. It allows you to use all the awesome features of the asset pipeline without all the heft of Rails.}

  s.required_ruby_version     = '>= 1.9.2'

  s.files         = Dir["README.md", "bin/**/*", "lib/**/*"]
  s.require_path  = "lib"
  
  s.bindir        = "bin"
  s.executables   = ["spar"]

  s.add_development_dependency "cucumber"
  s.add_development_dependency "aruba"

  s.add_dependency "rack",               '~> 1.4',  '>= 1.4.1'
  s.add_dependency "sinatra",            '~> 1.3',  '>= 1.3.2'
  s.add_dependency "sass",               '~> 3.1',  '>= 3.1.10'
  s.add_dependency "haml",               '~> 3.1',  '>= 3.1.4'
  s.add_dependency "coffee-script",      '~> 2.2',  '>= 2.2.0'
  s.add_dependency "uglifier",           '~> 1.0',  '>= 1.0.3'
  s.add_dependency "sprockets",          '~> 2.6',  '>= 2.6.0'
  s.add_dependency "compass",            '>= 0.12.2'
  s.add_dependency "sprockets-sass",     '~> 0.5',  '>= 0.5'
  s.add_dependency "bundler",            '~> 1.0',  '>= 1.0.18'
  s.add_dependency "thor",               '~> 0.15', '>= 0.15.2'
  s.add_dependency "rake",               '~> 0.9',  '>= 0.9.2'
  s.add_dependency 'listen',             '~> 0.4',  '>= 0.4.2'
  s.add_dependency 'test-unit'
  s.add_dependency 'mime-types'
  s.add_dependency 'aws-sdk'
  s.add_dependency 'rack-livereload'
  s.add_dependency 'yui-compressor'
  s.add_dependency 'bluecloth'
end
