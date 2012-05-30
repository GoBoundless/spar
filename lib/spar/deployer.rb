require 'logger'
require 'find'
require 'mime/types'
require 'aws-sdk'
require 'cloudfront-invalidator'

module Spar
  class Deployer

    def initialize(app, options = {})
      @app = app
      AWS.config(
        :access_key_id      => @app.aws_access_key_id,
        :secret_access_key  => @app.aws_secret_access_key,
        :logger             => Logger.new($stderr),
        :log_formatter      => AWS::Core::LogFormatter.colored
      )
      AWS.config.logger.level = Logger::WARN
      @s3 = AWS::S3.new
      @bucket         = @s3.buckets[App.s3_bucket]
      @max_age        = options.delete(:max_age) || 60 * 60 * 24 * 3 # 3 days 
      @zip_files      = options.delete(:zip_files) || /\.(?:css|html|js|svg|txt|xml)$/
      @view_paths     = app.precompile_view_paths || []
      @to_invalidate  = []
    end

    def upload_assets
      Dir.chdir(@app.public_path) do
        local = Find.find( 'assets' ).reject{|f| %w[assets/index.html assets/manifest.yml].index f}.reject! { |f| File.directory? f }
        remote = @bucket.objects.with_prefix( 'assets/' ).map{|o|o.key}.reject{|o| o =~ /\/$/ }
        to_delete = remote - local
        to_upload = local - remote
        @to_invalidate << to_upload

        to_upload.each do |file|

          headers = {
            :content_type => MIME::Types.of(file.gsub(/\.gz$/, '')).first, 
            :cache_control => 'public, max-age=86400',
            :acl => :public_read,
            :expires => (Time.now+60*60*24*365).httpdate
          }
          headers[:content_encoding] = :gzip if %w[svgz gz].index file.split('.').last
          
          logger "Uploading #{file}", headers
          @bucket.objects[file].write(headers.merge :data => File.read(file) )
        end
        age_out to_delete
      end
    end

    # TODO I really want this to call StaticCompiler#write_manifest directly. Another day.
    def upload_views
      Dir.chdir(@app.public_path) do
        Find.find( '.' ).to_a.select{|f| File.basename(f) == 'index.html' }.map{|f| f.gsub('./','') }.sort_by{|f|f.length}.each do |file|
          headers = {
            :content_type => 'text/html; charset=utf-8',
            :cache_control => 'public, max-age=60',
            :acl => :public_read
          }
          logger "Uploading #{file}", headers
          @bucket.objects[file].write(headers.merge :data => File.read(file) )
          @to_invalidate << 'file'
        end
      end
    end

    def upload_downloads
      # TODO This should be doing checksum comparisons so that downloads can be replaced.
      Dir.chdir(File.join(@app.root,'assets')) do
        return unless Dir.exists? 'downloads'
        local = Find.find( 'downloads' ).to_a.reject! { |f| File.directory? f }
        remote = @bucket.objects.with_prefix( 'downloads/' ).map{|o|o.key}.reject{|o| o =~ /\/$/ }
        to_delete = remote - local
        to_upload = local - remote
        @to_invalidate << to_upload

        to_upload.each do |file|

          headers = {
            :content_type => MIME::Types.of(file).first, 
            :content_disposition => "attachment; filename=#{File.basename(file)}",
            :cache_control => 'public, max-age=86400',
            :acl => :public_read,
            :expires => (Time.now+60*60*24*365).httpdate
          }
          
          logger "Uploading #{file}", headers
          @bucket.objects[file].write(headers.merge :data => File.read(file) )
        end
        age_out to_delete
      end
    end

    # Copy `assets/favicon-hash.ico` (if changed in this deployment) to /favicon.ico.
    def upload_favicon
      Dir.chdir(@app.public_path) do
        to_upload.select{ |path| path =~ /favicon/}.each do |hashed| # Should only be one.
          logger "Copying favicon.ico into place from #{hashed}"
          @bucket.objects[hashed].copy_to('favicon.ico', { :acl => :public_read })
          @to_invalidate << 'favicon.ico'
        end
      end
    end

    # Remove obsolete objects once they are sufficiently old
    def age_out(list)
      list.flatten.each do |file|
        if Time.now - @bucket.objects[file].last_modified > @max_age
          logger "Deleting #{file}"
          @bucket.objects[file].delete
        end
      end
    end

    # Add a file indicating time of most recent deploy.
    def timestamp!
      @bucket.objects['TIMESTAMP.txt'].write(
        :data => Time.now.to_s+"\n",
        :content_type => "text/plain",
        :acl => :public_read
      )
      @to_invalidate << 'TIMESTAMP.txt'
    end

    def deploy
      upload_assets
      upload_views
      upload_downloads
      timestamp! 
      invalidate_cloudfront
    end

    def invalidate_cloudfront
      @to_invalidate.flatten!
      @to_invalidate.uniq!
      logger "Issuing CloudFront invalidation request for #{@to_invalidate.count} objects."
      CloudfrontInvalidator.new(
        @app.aws_access_key_id,
        @app.aws_secret_access_key,
        @app.cloudfront_distribution,
      ).invalidate(@to_invalidate) do |status,time|
        puts "Invalidation #{status} after %.2f seconds" % time.to_f
      end
    end

    def logger(*args)
      STDERR.puts args.map{|x|x.to_s}.join(' ')
    end

  end
end

# MIME::Types has incomplete knowledge of how web fonts get served, and
# complains when we try to fix it.
module Kernel
  def suppress_warnings
    original_verbosity = $VERBOSE
    $VERBOSE = nil
    result = yield
    $VERBOSE = original_verbosity
    return result
  end
end

Kernel.suppress_warnings do
  MIME::Types.add(
    MIME::Type.new('image/svg+xml'){|t| t.extensions = %w[svgz]},
    MIME::Type.new('application/vnd.ms-fontobject'){|t| t.extensions = %w[eot]}
  )
end
