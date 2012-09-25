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

    desc 'server', 'Serve spar application'

    method_option :port, :aliases => '-p', :desc => 'Port'

    def server
      Rack::Server.start(
        :Port => options[:port] || 8888,
        :app  => Spar.app
      )
    end

    desc 'deploy', 'Deploy the project.'

    def deploy(environment='production')
      say "Deploying: #{Spar.root}"

      Spar.environment = environment
      
      if strategy = Spar.settings['deploy_strategy']
        require "spar/deployers/#{strategy}_deployer"

        deployer = Kernel.const_get("#{strategy.capitalize()}Deployer").new

        deployer.run(Spar::Compiler.assets)
      else
        raise "You are trying to deploy to the #{environment} environment, but you have not declared a :deploy_strategy in config.yml for this environment. The available options are: 'local', 's3', and 'cloudfront'."
      end
    end

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
