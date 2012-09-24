require 'sprockets'

module Spar
  module Helpers

    def self.paths
      @paths ||= Spar::Helpers::Paths.new()
    end

    def self.path_to(asset_name, options={})
      asset_name = asset_name.logical_path if asset_name.respond_to?(:logical_path)
      path = paths.compute_public_path(asset_name, options)
      options[:body] ? "#{path}?body=1" : path
    end

    def self.javascript_include_tag(*sources)
      sources.collect do |source|
        if Spar.settings['debug'] && asset = paths.asset_for(source, 'js')
          asset.to_a.map { |dep|
            javascript_tag(path_to(dep, :ext => 'js', :body => true))
          }
        else
          javascript_tag(path_to(source, :ext => 'js', :body => false))
        end
      end.join("\n")
    end

    def self.javascript_tag(src)
      "<script src='#{src}' charset='utf-8'></script>"
    end

    def self.stylesheet_link_tag(*sources)
      sources.collect do |source|
        if Spar.settings['debug'] && asset = paths.asset_for(source, 'css')
          asset.to_a.map { |dep|
            stylesheet_tag(path_to(dep, :ext => 'css', :body => true, :protocol => :request))
          }
        else
          stylesheet_tag(path_to(source, :ext => 'css', :body => false, :protocol => :request))
        end
      end.join("\n")
    end

    def self.stylesheet_tag(src)
      "<link href='#{src}' rel='stylesheet'>"
    end

    class Paths
      URI_REGEXP = %r{^[-a-z]+://|^cid:|^//}

      def asset_for(source, ext)
        source = source.to_s
        return nil if is_uri?(source)
        source = rewrite_extension(source, ext)
        Spar.sprockets[source]
      rescue Sprockets::FileOutsidePaths
        nil
      end

      def compute_public_path(source, options = {})
        source = source.to_s
        return source if is_uri?(source)

        source = rewrite_extension(source, options[:ext]) if options[:ext]
        source = rewrite_asset_path(source, options)
        source = rewrite_host_and_protocol(source, options[:protocol])
        source
      end

      def is_uri?(path)
        path =~ URI_REGEXP
      end

      def digest_for(logical_path)
        if Spar.settings['digests'] && asset = Spar.sprockets[logical_path]
          return asset.digest_path
        end
        return logical_path
      end

      def rewrite_asset_path(source, options = {})
        if source[0] == ?/
          source
        else
          source = digest_for(source)
          source = "/#{source}" unless source =~ /^\//
          source
        end
      end

      def rewrite_extension(source, ext)
        if ext && File.extname(source) != ".#{ext}"
          "#{source}.#{ext}"
        else
          source
        end
      end

      def rewrite_host_and_protocol(source, protocol = nil)
        Spar.settings['asset_host'] ? "#{Spar.settings['asset_host']}#{source}" : source
      end

    end
  end
end
