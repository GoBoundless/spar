require 'find'
require 'mime/types'
require 'aws-sdk'
require 'cloudfront-invalidator'

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

namespace :assets do
  desc "Compile all the assets"
  task :precompile => :clean do
    Spar::Helpers.configure do |config|
      config.compile_assets    = true
    end

    compiler = Spar::StaticCompiler.new(App)
    compiler.compile
  end

  desc "Remove compiled assets"
  task :clean => :environment do
    public_asset_path = File.join(App.public_path, App.asset_prefix)
    system "/bin/rm", "-rf", public_asset_path
  end
end

desc "Deploy a freshly precompiled site to S3 and purge CloudFront as is appropriate."
task :deploy => %w[ assets:precompile deploy:upload ]

namespace :deploy do

  desc "Upload assets to S3 as atomically as possible."
  task :upload do
    s3 = AWS::S3.new(
      :access_key_id => App.aws_access_key_id,
      :secret_access_key => App.aws_secret_access_key
    )

    bucket = s3.buckets[App.s3_bucket]

    Dir.chdir(App.public_path) do

      local = Find.find( 'assets' ).reject{|f| %w[assets/index.html assets/manifest.yml].index f}.reject! { |f| File.directory? f }
      remote = bucket.objects.with_prefix( 'assets/' ).map{|o|o.key}.reject{|o| o =~ /\/$/ }
      to_delete = remote - local
      to_upload = local - remote
      to_invalidate = to_upload

      to_upload.each do |file|

        headers = {
          :content_type => MIME::Types.of(file.gsub(/\.gz$/, '')).first, 
          :cache_control => 'public, max-age=86400',
          :acl => :public_read,
          :expires => (Time.now+60*60*24*365).httpdate
        }
        headers[:content_encoding] = :gzip if %w[svgz gz].index file.split('.').last
        
        STDERR.puts "Uploading #{file}", headers
        bucket.objects[file].write(headers.merge :data => File.open(file).read )

        # TODO: Make asset available without version component and short TTL for inclusion long-lived SEO documents

      end

      # Copy `assets/favicon-hash.ico` (if changed in this deployment) to /favicon.ico.
      to_upload.select{ |path| path =~ /favicon/}.each do |hashed| # Should only be one.
        unhashed = hashed.gsub(/assets\/favicon-[a-f0-9]{32}\.ico/,'favicon.ico')
        STDERR.puts "Copying favicon.ico into place from #{hashed}"
        bucket.objects[hashed].copy_to('favicon.ico', { :acl => :public_read })
        to_invalidate << 'favicon.ico'
      end

      # Upload index.html unconditionally
      headers = {
        :content_type => 'text/html; charset=utf-8',
        :cache_control => 'public, max-age=60',
        :acl => :public_read
      }
      STDERR.puts 'Uploading index.html', headers
      bucket.objects['index.html'].write(headers.merge :data => File.open('assets/index.html').read )
      to_invalidate << 'index.html'
      
      # Remove obsolete objects once they are sufficiently old
      to_delete.each do |file|
        if Time.now - bucket.objects[file].last_modified > 60*60
          STDERR.puts "Deleting #{file}"
          bucket.objects[file].delete
        end
      end

      # Add a file indicating time of most recent deploy.
      bucket.objects['TIMESTAMP.txt'].write(
        :data => Time.now.to_s+"\n",
        :content_type => "text/plain",
        :acl => :public_read
      )
      to_invalidate << 'TIMESTAMP.txt'

      # We have a very low TTL for index.html, and everything else is
      # essentially content-addressible, so invalidating CloudFront is really
      # just icing on the cake.
      STDERR.puts "Issuing invalidation request for #{to_invalidate.count} objects."
      CloudfrontInvalidator.new(
        App.aws_access_key_id,
        App.aws_secret_access_key,
        App.cloudfront_distribution,
      ).invalidate(to_invalidate)

    end

  end

end
