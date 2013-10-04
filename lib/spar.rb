require 'rack'
require 'pathname'
require 'sprockets'
require 'haml'
require 'sass'
require 'sprockets-sass'
require 'compass'
require 'coffee-script'
require 'haml_coffee_assets'

module Spar
  autoload :Version, 'spar/version'
  autoload :CLI, 'spar/cli'
  autoload :Rewrite, 'spar/rewrite'
  autoload :Exceptions, 'spar/exceptions'
  autoload :DirectiveProcessor, 'spar/directive_processor'
  autoload :Helpers, 'spar/helpers'
  autoload :Compressor, 'spar/compressor'
  autoload :Compiler, 'spar/compiler'
  autoload :CompiledAsset, 'spar/compiled_asset'
  autoload :Deployer, 'spar/deployers/deployer'
  autoload :Assets, 'spar/assets'
  autoload :Static, 'spar/static'
  autoload :NotFound, 'spar/not_found'

  DEFAULTS = {
    'digest'   => false,
    'debug'    => true,
    'compress' => false,
    'js_compressor' => {
      'mangle' => false
    },
    'css_compressor' => {},
    'cache_control'  => "public, max-age=#{60 * 60 * 24 * 7}"
  }

  def self.root
    @root ||= begin
      # Remove the line number from backtraces making sure we don't leave anything behind
      call_stack = caller.map { |p| p.sub(/:\d+.*/, '') }
      root_path = File.dirname(call_stack.detect { |p| p !~ %r[[\w.-]*/lib/spar|rack[\w.-]*/lib/rack] })

      while root_path && File.directory?(root_path) && !File.exist?("#{root_path}/config.yml")
        parent = File.dirname(root_path)
        root_path = parent != root_path && parent
      end

      root = File.exist?("#{root_path}/config.yml") ? root_path : Dir.pwd
      raise "Could not find root path for #{self}" unless root

      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? Pathname.new(root).expand_path : Pathname.new(root).realpath   
    end
  end

  def self.environment=(environment)
    @environment = environment
  end

  def self.environment
    @environment ||= ENV['SPAR_ENV'] || ENV['RACK_ENV'] || 'development'
  end

  def self.assets
    @assets ||= Spar::Assets.new
  end

  def self.static
    @static ||= Spar::Static.new
  end

  def self.not_found
    @not_found ||= Spar::NotFound.new
  end

  def self.sprockets
    @sprockets ||= begin
      env = Sprockets::Environment.new(root)

      HamlCoffeeAssets.config.namespace  = "window.HAML"
      HamlCoffeeAssets.config.escapeHtml = false

      Compass.configuration.project_path = "app"
      Compass.configuration.images_path  = "app/images"
      Compass.configuration.fonts_path   = "app/fonts"

      if settings['compress']
        env.js_compressor  = Compressor::JS.new
        env.css_compressor = Compressor::CSS.new
      end

      child_folders = ['javascripts', 'stylesheets', 'images', 'pages', 'fonts']

      for child_folder in child_folders
        env.append_path(root.join('app', child_folder))
        env.append_path(root.join('vendor', child_folder))
        Gem.loaded_specs.each do |name, gem|
          env.append_path(File.join(gem.full_gem_path, 'vendor', 'assets', child_folder))
          env.append_path(File.join(gem.full_gem_path, 'app', 'assets', child_folder))
        end
      end

      env.append_path(root.join('components'))

      for path in (settings['paths'] || [])
        env.append_path(root.join(*path.split('/')))
      end

      env.register_engine '.haml',    Tilt::HamlTemplate

      env.register_postprocessor 'text/css',               Spar::DirectiveProcessor
      env.register_postprocessor 'application/javascript', Spar::DirectiveProcessor
      env.register_postprocessor 'text/html',              Spar::DirectiveProcessor

      env
    end

    unless @already_externally_configured
      @already_externally_configured = true
      external_config_pathname = Pathname.new(Spar.root).join("config.rb")
      load external_config_pathname if File.exist?(external_config_pathname)
    end

    @sprockets
  end

  def self.app
    app = Rack::Builder.new do
      use Spar::Rewrite
      use Spar::Exceptions

      run Rack::Cascade.new([Spar.static, Spar.sprockets, Spar.not_found])

      use Rack::ContentType
    end
  end

  def self.settings
    @settings ||= load_config
  end

  protected
  
    def self.load_config
      pathname = Pathname.new(Spar.root).join("config.yml")
      begin
        yaml = YAML.load_file(pathname)
        settings = DEFAULTS.merge(yaml['default'] || {}).merge(yaml[environment] || {})
        settings['environment'] = environment
        settings
      rescue => e
        raise "Could not load the config.yml file: #{e.message}"
      end
    end

end

module Sprockets
  class Context
    include Spar::Helpers
  end
end

module Sass::Script::Functions
  def generated_image_url(path, only_path = nil)
    asset_url(path, Sass::Script::String.new("image"))
  end
end
