require 'sprockets'
require 'sprockets-sass'
require 'sprockets-helpers'
require 'coffee_script'

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

      app.configure do
        app.set :asset_digests, true
        app.set :asset_host, '/'
      end

      app.configure :development do
        app.set :asset_digests, true
        app.set :asset_host, '/'
      end

      app.asset_dirs.each do |asset_type|
        app.asset_env.append_path(File.join(app.asset_path, asset_type))
        app.asset_env.append_path(File.join(Spar.root, 'vendor', DEFAULT_PREFIX, asset_type))
        Gem.loaded_specs.each do |name, gem|
          app.asset_env.append_path(File.join(gem.full_gem_path, 'vendor', DEFAULT_PREFIX, asset_type))
        end
      end

      Sprockets::Helpers.configure do |config|
        config.environment = app.asset_env
        config.prefix      = "#{app.asset_host}#{app.asset_prefix}"
        config.digest      = app.asset_digests
      end

      app.helpers do
        include Sprockets::Helpers
      end

    end

  end
end