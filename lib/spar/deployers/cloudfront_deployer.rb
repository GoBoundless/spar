require 'cloudfront-invalidator'
require 'spar/deployers/s3_deployer'

class CloudfrontDeployer < S3Deployer

  def prepare(assets)
    super
    @cloudfront_distribution = Spar.settings['cloudfront_distribution']
    raise "ERROR: You should set a :cloudfront_distribution in your config.yml file so you can deploy to Cloudfront" unless @cloudfront_distribution
    @invalidator = CloudfrontInvalidator.new(
      @aws_key,
      @aws_secret,
      @cloudfront_distribution
    )
  end

  def finish
    to_invalidate = @deployed_assets.collect do |asset|
      if asset.write_path =~ /\.html$/
        [ asset.write_path, asset.write_path.gsub('index.html',''), asset.write_path.gsub('/index.html','') ]
      else
        asset.write_path
      end
    end
    to_invalidate << 'TIMESTAMP.txt'

    @invalidator.invalidate(to_invalidate.flatten) do |status,time|
      puts "Invalidation #{status} after %.2f seconds" % time.to_f
    end

    super
  end

end
