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

    # method_option :target, :aliases => '-t', :desc => 'Directory to compile assets to'

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

    method_option :css, :desc => 'Use css instead of sass'
    method_option :html, :desc => 'Use html instead of haml'
    method_option :js, :desc => 'Use js instead of coffeescript'
    
    def new(name)
      # first, copy in the base directory
      directory('lib/spar/generators/templates/base', name)
      
      if !options[:css]
        # copy in the sass files
        directory('lib/spar/generators/templates/styles/sass', name)
      else
        # copy in the css files
        directory('lib/spar/generators/templates/styles/css', name)
      end
      
      if !options[:html]
        # copy in the haml files
        directory('lib/spar/generators/templates/pages/haml', name)
      else
        # copy in the html files
        directory('lib/spar/generators/templates/pages/html', name)
      end
      
      if !options[:js]
        # copy in the coffee files
        directory('lib/spar/generators/templates/scripts/coffee', name)
      else
        # copy in the js files
        directory('lib/spar/generators/templates/scripts/js', name)
      end
    end
  end
end
