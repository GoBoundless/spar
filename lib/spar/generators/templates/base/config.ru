require 'rubygems'
require 'bundler/setup'
Bundler.require if File.exists?('Gemfile')

map "/" do
  run Spar.app
end