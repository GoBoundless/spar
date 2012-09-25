require 'logger'
require 'find'
require 'mime/types'
require 'aws-sdk'
require 'cloudfront-invalidator'

module Spar
  module Deployer

    def self.deploy
      unless Spar.settings['aws_key'] and Spar.settings['aws_secret'] and Spar.settings['deploy_bucket']
        raise ":aws_key, :aws_secret, and :deploy_bucket are all required for deployment")
      end
      AWS.config(
        :access_key_id      => Spar.settings['aws_key'],
        :secret_access_key  => Spar.settings['aws_secret'],
        :logger             => Logger.new($stderr),
        :log_formatter      => AWS::Core::LogFormatter.colored
      )
      AWS.config.logger.level = Logger::WARN
      @s3 = AWS::S3.new
      @bucket         = @s3.buckets[Spar.settings['deploy_bucket']]
      @age_out        = 60 * 60 * 24 * 3 # 3 days 
      @to_invalidate  = []
      @manifest = YAML.read_file("#{Spar.root}/public/compiled/manifest.yml")

      Dir.chdir("#{Spar.root}/public") do
        local_compiled_files  = Find.find('compiled').reject{ |f| %w[manifest.yml].index f }.reject! { |f| File.directory? f }
        local_static_files    = Find.find('.').reject{ |f| f =~ /compiled\// }.reject! { |f| File.directory? f }
        remote_files = @bucket.objects.map{ |o| o.key }.reject{ |o| o =~ /\/$/ }
        to_delete = remote - (local_compiled_files + local_static_files)
        to_upload = (local_compiled_files + local_static_files) - remote
        to_check  = remote & (local_compiled_files + local_static_files)
        
        to_check.each do |file|
          if @bucket.objects[file].etag.gsub(/\"/,'') != Digest::MD5.hexdigest(File.read(file))
            logger "Etag mismatch for: #{file}"
            write_file(file)
            if file =~ /\/.html$/
              @to_invalidate << [file, file.gsub('/index.html', ''), ffile.gsub('index.html', '')]
            else
              @to_invalidate << file
            end
          end
        end

        to_upload.each do |file|
          write_file(file)
        end

        age_out to_delete
      end

      timestamp!
      invalidate_cloudfront
    end

    def self.write_file(file)
      if file =~ /\/.html$/
        headers = {
          :content_type => 'text/html; charset=utf-8',
          :cache_control => @manifest[file][:cache],
          :acl => :public_read
        }
      else
        headers = {
          :content_type => MIME::Types.of(file.gsub(/\.?gz$/, '')).first, 
          :cache_control => @manifest[file][:cache],
          :acl => :public_read
        }
        headers[:content_encoding] = :gzip if %w[svgz gz].index file.split('.').last
      end
      
      logger "Uploading #{file}", headers
      @bucket.objects[file].write(headers.merge :data => File.read(file) )
    end

    def self.age_out(list)
      list.flatten.each do |file|
        if Time.now - @bucket.objects[file].last_modified > @age_out
          logger "Deleting #{file}"
          @bucket.objects[file].delete
        end
      end
    end

    # Add a file indicating time of most recent deploy.
    def self.timestamp!
      @bucket.objects['TIMESTAMP.txt'].write(
        :data => Time.now.to_s+"\n",
        :content_type => "text/plain",
        :acl => :public_read
      )
      @to_invalidate << 'TIMESTAMP.txt'
    end

    def self.invalidate_cloudfront
      return unless @app.respond_to? :cloudfront_distribution
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

    def self.logger(*args)
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
