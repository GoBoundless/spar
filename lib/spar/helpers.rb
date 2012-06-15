require 'sprockets'

module Spar
  module Helpers

    class << self
      # When true, the asset paths will return digest paths.
      attr_accessor :asset_environment, :asset_prefix, :digest_assets, :asset_digests, :compile_assets, :debug_assets, :asset_host
      
      # Convience method for configuring Sprockets::Helpers.
      def configure
        yield self
      end
    end

    def asset_paths
      @asset_paths ||= begin
        paths = Spar::Helpers::AssetPaths.new()
        paths.asset_environment = Helpers.asset_environment
        paths.asset_digests     = Helpers.asset_digests
        paths.compile_assets    = compile_assets?
        paths.digest_assets     = digest_assets?
        paths.asset_host        = Helpers.asset_host
        paths
      end
    end

    def javascript_include_tag(*sources)
      sources.collect do |source|
        if debug_assets? && asset = asset_paths.asset_for(source, 'js')
          asset.to_a.map { |dep|
            javascript_tag(asset_path(dep, :ext => 'js', :body => true, :digest => digest_assets?))
          }
        else
          javascript_tag(asset_path(source, :ext => 'js', :body => false, :digest => digest_assets?))
        end
      end.join("\n")
    end

    def javascript_tag(src)
      "<script src='#{src}'></script>"
    end

    def stylesheet_link_tag(*sources)
      sources.collect do |source|
        if debug_assets? && asset = asset_paths.asset_for(source, 'css')
          asset.to_a.map { |dep|
            stylesheet_tag(asset_path(dep, :ext => 'css', :body => true, :protocol => :request, :digest => digest_assets?))
          }
        else
          stylesheet_tag(asset_path(source, :ext => 'css', :body => false, :protocol => :request, :digest => digest_assets?))
        end
      end.join("\n")
    end

    def stylesheet_tag(src)
      "<link href='#{src}' rel='stylesheet'>"
    end

    def asset_path(source, options = {})
      source = source.logical_path if source.respond_to?(:logical_path)
      path = asset_paths.compute_public_path(source, Helpers.asset_prefix, options.merge(:body => true))
      options[:body] ? "#{path}?body=1" : path
    end

    def image_path(source)
      asset_path(source)
    end

    def font_path(source)
      asset_path(source)
    end

    def javascript_path(source)
      asset_path(source, :ext => 'js')
    end

    def stylesheet_path(source)
      asset_path(source, :ext => 'css')
    end

  private
    def debug_assets?
      compile_assets? && !!Helpers.debug_assets
    rescue NameError
      false
    end

    def compile_assets?
      !!Helpers.compile_assets
    end

    def digest_assets?
      !!Helpers.digest_assets
    end

    class AssetPaths
      URI_REGEXP = %r{^[-a-z]+://|^cid:|^//}

      attr_accessor :asset_environment, :asset_digests, :compile_assets, :digest_assets, :asset_host

      class AssetNotPrecompiledError < StandardError; end

      def asset_for(source, ext)
        source = source.to_s
        return nil if is_uri?(source)
        source = rewrite_extension(source, nil, ext)
        asset_environment[source]
      rescue Sprockets::FileOutsidePaths
        nil
      end

      def compute_public_path(source, dir, options = {})
        source = source.to_s
        return source if is_uri?(source)

        source = rewrite_extension(source, dir, options[:ext]) if options[:ext]
        source = rewrite_asset_path(source, dir, options)
        source = rewrite_host_and_protocol(source, options[:protocol])
        source = rewrite_for_compression(source)
        source
      end

      def is_uri?(path)
        path =~ URI_REGEXP
      end

      def digest_for(logical_path)
        if digest_assets && asset_digests && (digest = asset_digests[logical_path])
          return digest
        end

        if compile_assets
          if digest_assets && asset = asset_environment[logical_path]
            return asset.digest_path
          end
          return logical_path
        else
          raise AssetNotPrecompiledError.new("#{logical_path} isn't precompiled")
        end
      end

      def rewrite_asset_path(source, dir, options = {})
        if source[0] == ?/
          source
        else
          source = digest_for(source) unless options[:digest] == false
          source = File.join(dir, source)
          source = "/#{source}" unless source =~ /^\//
          source
        end
      end

      def rewrite_extension(source, dir, ext)
        if ext && File.extname(source) != ".#{ext}"
          "#{source}.#{ext}"
        else
          source
        end
      end

      def rewrite_for_compression(source)
        if App.request_gzip and %w[.js .css].index File.extname(source)
          source + 'gz'
        else
          source
        end
      end

      def rewrite_host_and_protocol(source, protocol = nil)
        asset_host ? "#{asset_host}#{source}" : source
      end

    end
  end
end
