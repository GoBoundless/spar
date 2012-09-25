require 'mime/types'

module Spar

  class CompiledAsset

    attr_accessor :asset, :logical_path, :write_path, :headers, :mtime, :digest

    def initialize(asset, options={})
      if asset.is_a?(String)
        @file = File.new(asset, 'rb')
        @logical_path = asset
      else
        @asset = asset
        @logical_path = @asset.logical_path
      end
      @write_path = generate_write_path(options)
      @headers    = generate_headers(options)
      @mtime      = (@asset || @file).mtime
      @digest     = @asset ? @asset.digest : Digest::MD5.hexdigest(data)
    end

    def generate_write_path(options)
      if options[:digest] && @asset
        @asset.digest_path
      else
        @asset ? @logical_path : @logical_path.gsub(/^public\//,'')
      end
    end

    def generate_headers(options)
      headers = {
        :cache_control => options[:cache_control] || Spar.settings['cache_control'],
        :acl => :public_read
      }

      if @write_path =~ /\/.html$/
        headers[:content_type] = 'text/html; charset=utf-8'
      else
        headers[:content_type] = MIME::Types.of(@write_path).first
      end

      if @logical_path =~ /public\/downloads\//
        headers[:content_disposition] = "attachment; filename=#{File.basename(@write_path)}"
      end

      headers[:content_encoding] = :gzip if %w[svgz gz].index @write_path.split('.').last
      
      headers
    end

    def data
      @data ||= @asset ? @asset.to_s : @file.read
    end

    def write_to(base_path, options = {})
      filename = File.join(base_path, @write_path)
      # Gzip contents if filename has '.gz'
      options[:compress] ||= File.extname(filename) == '.gz'

      FileUtils.mkdir_p File.dirname(filename)

      File.open("#{filename}+", 'wb') do |f|
        if options[:compress]
          # Run contents through `Zlib`
          gz = Zlib::GzipWriter.new(f, Zlib::BEST_COMPRESSION)
          gz.mtime = @mtime.to_i
          gz.write data
          gz.close
        else
          # Write out as is
          f.write data
          f.close
        end
      end

      # Atomic write
      FileUtils.mv("#{filename}+", filename)

      # Set mtime correctly
      File.utime(@mtime, @mtime, filename)

      nil
    ensure
      # Ensure tmp file gets cleaned up
      FileUtils.rm("#{filename}+") if File.exist?("#{filename}+")
    end

  end
end