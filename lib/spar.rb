require 'pathname'
require 'sprockets'
require 'haml'

module Spar
  autoload :Version, 'spar/version'
  autoload :CLI, 'spar/cli'
  autoload :Rewrite, 'spar/rewrite'
  autoload :DirectiveProcessor, 'spar/directive_processor'
  autoload :Helpers, 'spar/helpers'
  autoload :Compressor, 'spar/compressor'
  autoload :Compiler, 'spar/compiler'
  autoload :CompiledAsset, 'spar/compiled_asset'
  autoload :Deployer, 'spar/deployers/deployer'

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

      while root_path && File.directory?(root_path) && !File.exist?("#{root_path}/config.ru")
        parent = File.dirname(root_path)
        root_path = parent != root_path && parent
      end

      root = File.exist?("#{root_path}/config.ru") ? root_path : Dir.pwd
      raise "Could not find root path for #{self}" unless root

      RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? Pathname.new(root).expand_path : Pathname.new(root).realpath   
    end
  end

  def self.environment=(environment)
    @environment = environment
  end

  def self.sprockets
    @sprockets ||= begin
      @environment ||= ENV['SPAR_ENV'] || 'development'

      env = Sprockets::Environment.new(root)

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
          env.append_path(File.join(gem.full_gem_path, 'app', 'assets', 'assets', child_folder))
        end
      end

      env.append_path(root.join('components'))

      for path in (settings['paths'] || [])
        env.append_path(root.join(*path.split('/')))
      end

      env.register_engine '.haml',    Tilt::HamlTemplate
      env.register_engine '.md',      Tilt::BlueClothTemplate
      env.register_engine '.textile', Tilt::RedClothTemplate

      env.register_postprocessor 'text/css',               Spar::DirectiveProcessor
      env.register_postprocessor 'application/javascript', Spar::DirectiveProcessor
      env.register_postprocessor 'text/html',              Spar::DirectiveProcessor

      env
    end
  end

  def self.app
    app = Rack::Builder.new do

      use Spar::Rewrite

      map '/' do
        run Spar.sprockets
      end

      use Rack::Static, :root => Spar.root.join('public'), :urls => %w[/]

      use Rack::ContentType

      run lambda { |env|
        [404, {}, ['Not found']]
      }
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
        settings = DEFAULTS.merge(yaml['default'] || {}).merge(yaml[@environment] || {})
        settings['environment'] = @environment
        settings
      rescue => e
        raise "Could not load the config.yml file: #{e.message}"
      end
    end

end
