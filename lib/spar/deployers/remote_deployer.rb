require 'net/scp'
require 'fileutils'

class RemoteDeployer < Spar::Deployer

  def prepare(assets)
    @host     = Spar.settings['remote_host']
    @username = Spar.settings['remote_username']
    @password = Spar.settings['remote_password']
    @deploy_path = Spar.settings['remote_path']
    unless @host and @username and @password and @deploy_path
      raise "ERROR: You should set :remote_host, :remote_username, :remote_password and :remote_path in your config.yml file so you can deploy to remote server"
    end

    super    
  end

  def deploy(asset)
    asset.write_to('/tmp')
    Net::SCP.upload!(@host, @username, "/tmp/#{asset.write_path}", @deploy_path, :password => @password)    
    super
  end

  def finish    
    FileUtils.rm_rf 'tmp'    
  end

end
