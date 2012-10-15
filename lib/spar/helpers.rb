require 'sprockets'

module Spar
  module Helpers

    class << self

      def paths
        @paths ||= Spar::Helpers::Paths.new()
      end
      
      def append_features(context) # :nodoc:
        context.class_eval do
          context_methods = context.instance_methods(false)
          Helpers.public_instance_methods.each do |method|
            remove_method(method) if context_methods.include?(method)
          end
        end

        super(context)
      end

    end

    def path_to(asset_name, options={})
      asset_name = asset_name.logical_path if asset_name.respond_to?(:logical_path)
      path = Helpers.paths.compute_public_path(asset_name, options.merge(:body => true))
      options[:body] ? "#{path}?body=1" : path
    end

    def javascript_include_tag(*sources)
      sources.collect do |source|
        if Spar.settings['debug'] && asset = Helpers.paths.asset_for(source, 'js')
          asset.to_a.map { |dep|
            javascript_tag(path_to(dep, :ext => 'js', :body => true))
          }
        else
          javascript_tag(path_to(source, :ext => 'js', :body => false))
        end
      end.join("\n")
    end

    def javascript_tag(src)
      "<script src='#{src}' charset='utf-8'></script>"
    end

    def stylesheet_link_tag(*sources)
      sources.collect do |source|
        if Spar.settings['debug'] && asset = Helpers.paths.asset_for(source, 'css')
          asset.to_a.map { |dep|
            stylesheet_tag(path_to(dep, :ext => 'css', :body => true, :protocol => :request))
          }
        else
          stylesheet_tag(path_to(source, :ext => 'css', :body => false, :protocol => :request))
        end
      end.join("\n")
    end

    def stylesheet_tag(src)
      "<link href='#{src}' rel='stylesheet'>"
    end

    ## Helper methods for the spar context
    def audio_path(source, options = {})
      path_to source, { :dir => 'audios' }.merge(options)
    end
    alias_method :path_to_audio, :audio_path

    def font_path(source, options = {})
      path_to source, { :dir => 'fonts' }.merge(options)
    end
    alias_method :path_to_font, :font_path

    def image_path(source, options = {})
      path_to source, { :dir => 'images' }.merge(options)
    end
    alias_method :path_to_image, :image_path

    def javascript_path(source, options = {})
      path_to source, { :dir => 'javascripts', :ext => 'js' }.merge(options)
    end
    alias_method :path_to_javascript, :javascript_path

    def stylesheet_path(source, options = {})
      path_to source, { :dir => 'stylesheets', :ext => 'css' }.merge(options)
    end
    alias_method :path_to_stylesheet, :stylesheet_path

    def video_path(source, options = {})
      path_to source, { :dir => 'videos' }.merge(options)
    end
    alias_method :path_to_video, :video_path

    class Paths
      URI_REGEXP = %r{^[-a-z]+://|^cid:|^//}

      def asset_for(source, ext, options={})
        source = source.to_s
        return nil if is_uri?(source)
        source = rewrite_extension(source, ext)
        Spar.sprockets.find_asset(source, options)
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

      def digest_for(logical_path, options={})
        if Spar.settings['digest'] && !Spar.settings['debug'] && asset = Spar.sprockets.find_asset(logical_path, options)
          return asset.digest_path
        end
        return logical_path
      end

      def rewrite_asset_path(source, options = {})
        if source[0] == ?/
          source
        else
          source = digest_for(source, options)
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
