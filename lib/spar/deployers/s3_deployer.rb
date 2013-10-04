require 'aws-sdk'

class S3Deployer < Spar::Deployer

  def prepare(assets)
    @aws_key       = Spar.settings['aws_key']
    @aws_secret    = Spar.settings['aws_secret']
    @deploy_bucket = Spar.settings['deploy_bucket']
    @s3_endpoint   = Spar.settings['s3_endpoint'] || AWS.config.s3_endpoint
    unless @aws_key and @aws_secret and @deploy_bucket
      raise "ERROR: You should set :aws_key, :aws_secret, and :deploy_bucket in your config.yml file so you can deploy to S3"
    end
    
    AWS.config(
      :access_key_id      => @aws_key,
      :secret_access_key  => @aws_secret,
      :s3_endpoint        => @s3_endpoint
    )
    @s3 = AWS::S3.new
    @bucket  = @s3.buckets[@deploy_bucket]
    unless @bucket.exists?
      @bucket = @s3.buckets.create(@deploy_bucket)
    end
    @age_out = 60 * 60 * 24 * 3 # 3 days 

    super

    local_assets = assets.map(&:write_path)
    remote_assets = @bucket.objects.map{ |object| object.key }.reject{ |key| key =~ /\/$/ }

    age_out (remote_assets - local_assets)
  end

  def age_out(old_assets)
    old_assets.flatten.each do |file|
      if Time.now - @bucket.objects[file].last_modified > @age_out
        @bucket.objects[file].delete
      end
    end
  end

  def deploy(asset)
    remote_file = @bucket.objects[asset.write_path]
    if remote_file.exists?
      if remote_file.etag.gsub(/\"/,'') != asset.digest
        upload(asset)
        super
      end
    else
      upload(asset)
      super
    end
  end

  def upload(asset)
    if asset.write_path =~ /\.html$/ && !(asset.write_path =~ /\/?index\.html$/)
      @bucket.objects[asset.write_path.gsub(/\.html/, '/index.html')].write(asset.headers.merge(:data => asset.data))
    else
      @bucket.objects[asset.write_path].write(asset.headers.merge(:data => asset.data))
    end
  end

  def finish
    @bucket.objects['TIMESTAMP.txt'].write(
      :data => Time.now.to_s+"\n",
      :content_type => "text/plain",
      :acl => :public_read
    )
    super
  end

end
