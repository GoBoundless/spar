require 'sprockets'
require 'sprockets-sass'
require 'coffee_script'
require 'uglifier'

module Spar
  module Assets

    DEFAULT_DIRS       = ['stylesheets', 'javascripts', 'images', 'fonts']
    DEFAULT_PRECOMPILE = [ /\w+\.(?!js|css).+/, /application.(css|js)$/ ]
    DEFAULT_PREFIX     = 'assets'

    def self.registered(app)
      app.set :asset_env, Sprockets::Environment.new(app.root)
      app.set :asset_precomile, app.respond_to?(:asset_precomile) ? app.asset_precomile : DEFAULT_PRECOMPILE
      app.set :asset_dirs, app.respond_to?(:asset_dirs) ? app.asset_dirs : DEFAULT_DIRS
      app.set :asset_prefix, app.respond_to?(:asset_prefix) ? app.asset_prefix : DEFAULT_PREFIX
      app.set :asset_path, File.join(app.root, app.asset_prefix)
      app.set :manifest_path, File.join(app.public_path, app.asset_prefix, "manifest.yml")

      app.configure :production, :staging do
        app.set :request_gzip, true unless app.respond_to?(:request_gzip)
        app.set :assets_debug, false unless app.respond_to?(:assets_debug)
        app.set :asset_digest, true unless app.respond_to?(:asset_digests)
        app.set :asset_host, nil unless app.respond_to?(:asset_host)
        app.set :asset_compile, false unless app.respond_to?(:asset_compile)
        app.asset_env.js_compressor = Uglifier.new(:mangle => false)
        app.asset_env.css_compressor = CssCompressor.new
      end

      app.configure :development, :test do
        app.set :request_gzip, false unless app.respond_to?(:request_gzip)
        app.set :assets_debug, true unless app.respond_to?(:assets_debug)
        app.set :asset_digest, false unless app.respond_to?(:asset_digests)
        app.set :asset_host, nil unless app.respond_to?(:asset_host)
        app.set :asset_compile, true unless app.respond_to?(:asset_compile)
      end

      app.asset_dirs.each do |asset_type|
        app.asset_env.append_path(File.join(app.asset_path, asset_type))
        app.asset_env.append_path(File.join(Spar.root, 'lib', DEFAULT_PREFIX, asset_type))
        app.asset_env.append_path(File.join(Spar.root, 'vendor', DEFAULT_PREFIX, asset_type))
        Gem.loaded_specs.each do |name, gem|
          app.asset_env.append_path(File.join(gem.full_gem_path, 'vendor', DEFAULT_PREFIX, asset_type))
          app.asset_env.append_path(File.join(gem.full_gem_path, 'app', 'assets', DEFAULT_PREFIX, asset_type))
        end
      end

      if File.exist?(app.manifest_path)
        app.set :asset_digests, YAML.load_file(app.manifest_path)
      else
        app.set :asset_digests, {}
      end

      Spar::Helpers.configure do |config|
        config.asset_environment = app.asset_env
        config.asset_prefix      = app.asset_prefix
        config.compile_assets    = app.asset_compile
        config.debug_assets      = app.assets_debug
        config.digest_assets     = app.asset_digest
        config.asset_digests     = app.asset_digests
        config.asset_host        = app.asset_host
      end

      app.asset_env.context_class.instance_eval do
        include ::Spar::Helpers
      end

      app.helpers do
        include Spar::Helpers
      end

    end

  end
end
