require 'pathname'
require 'fileutils'
require 'listen'
require 'rack'
require 'thor'

module Spar
  class CLI < Thor
    include Thor::Actions

    def self.source_root
      File.expand_path('../../..', __FILE__)
    end

    # desc 'build [asset1 asset2..]', 'Build project'

    method_option :target, :aliases => '-t', :desc => 'Directory to compile assets to'
    method_option :compile, :type => :boolean, :aliases => '-c', :desc => 'Compile and minify assets'

    # def build(*assets)
    #   target = Pathname(options[:target] || './public/assets')

    #   if options[:compile]
    #     Catapult.environment.js_compressor  = Compressor::JS.new
    #     Catapult.environment.css_compressor = Compressor::CSS.new
    #   end

    #   say "Building: #{Catapult.root}"

    #   Catapult.environment.each_logical_path(assets) do |logical_path|
    #     if asset = Catapult.environment.find_asset(logical_path)
    #       filename = target.join(logical_path)
    #       FileUtils.mkpath(filename.dirname)
    #       say "Write asset: #{filename}"
    #       asset.write_to(filename)
    #     end
    #   end
    # end

    desc 'server', 'Serve spar application'

    method_option :port, :aliases => '-p', :desc => 'Port'

    def server
      Rack::Server.start(
        :Port => options[:port] || 8888,
        :app  => Spar.app
      )
    end

    # desc 'watch [asset1 asset2..]', 'Build project whenever it changes'

    # method_option :target, :aliases => '-t', :desc => 'Directory to compile assets to'

    # def watch(*assets)
    #   say "Watching: #{Catapult.root}"

    #   build(*assets)

    #   paths = Catapult.environment.paths
    #   paths = paths.select {|p| File.exists?(p) }

    #   Listen.to(*paths) { build }
    # end

    desc 'version', 'Show the current version of Spar'

    def version
      puts "Spar Version #{Spar::VERSION}"
    end

    desc 'new', 'Create a new spar project'

    def new(name)
      directory('lib/spar/generators/templates', name)
    end
  end
end