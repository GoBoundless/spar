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
        app.set :assets_debug, false
        app.set :asset_digests, true
        app.set :asset_host, '/'
      end

      app.configure :development do
        app.set :assets_debug, true
        app.set :asset_digests, false
        app.set :asset_host, '/'
      end

      app.asset_dirs.each do |asset_type|
        app.asset_env.append_path(File.join(app.asset_path, asset_type))
        app.asset_env.append_path(File.join(Spar.root, 'lib', DEFAULT_PREFIX, asset_type))
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

        def javascript_include_tag(*sources)
          sources.collect do |source|
            if settings.assets_debug && asset = asset_for(source, 'js')
              asset.to_a.map { |dep|
                javascript_tag(settings.asset_digests ? dep.digest_path : dep.logical_path)
              }
            else
              javascript_tag(source)
            end
          end.join("\n")
        end

        def javascript_tag(source)
          "<script src='#{javascript_path(source)}'></script>"
        end

        def asset_for(source, ext)
          if ext && File.extname(source) != ".#{ext}"
            source = "#{source}.#{ext}"
          end

          return nil if source =~ Sprockets::Helpers::URI_MATCH

          settings.asset_env[source]
        end
      end

    end

  end
end