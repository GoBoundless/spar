require 'pathname'
require 'sprockets'

module Spar
  autoload :Version, 'spar/version'
  autoload :CLI, 'spar/cli'
  # autoload :Assets, 'spar/assets'
  # autoload :StaticCompiler, 'spar/static_compiler'
  # autoload :Helpers, 'spar/helpers'
  # autoload :CssCompressor, 'spar/css_compressor'
  # autoload :Deployer, 'spar/deployer'

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

  def self.environment
    @environment ||= begin
      env = Sprockets::Environment.new(root)

      env.append_path(root.join('app', 'javascripts'))
      env.append_path(root.join('app', 'stylesheets'))
      env.append_path(root.join('app', 'images'))
      env.append_path(root.join('app', 'fonts'))
      env.append_path(root.join('app', 'views'))

      env.append_path(root.join('lib', 'javascripts'))
      env.append_path(root.join('lib', 'stylesheets'))

      env.append_path(root.join('vendor', 'javascripts'))
      env.append_path(root.join('vendor', 'stylesheets'))

      env.append_path(root.join('components'))

      env.register_engine '.haml',    Tilt::HamlTemplate
      env.register_engine '.md',      Tilt::BlueClothTemplate
      env.register_engine '.textile', Tilt::RedClothTemplate

      env
    end
  end

  def self.app
    app = Rack::Builder.new do
      map '/' do
        run Spar.environment
      end

      # use Catapult::TryStatic,
      #     :root => Catapult.root.join('public'),
      #     :urls => %w[/],
      #     :try  => ['.html', 'index.html', '/index.html']

      # use Rack::ContentType

      run lambda {|env|
        [404, {}, ['Not found']]
      }
    end
  end

end
