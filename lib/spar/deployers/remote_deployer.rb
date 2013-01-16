require 'net/ssh'
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
    puts "Uploading: #{asset.write_path}"
    asset.write_to("tmp")
    upload(asset)
    super
  end

  def upload(asset)
      Net::SSH.start(@host, @username, :password => @password) do |ssh|
          remote_dir = File.join(@deploy_path, File.dirname(asset.write_path))
          ssh.exec!("mkdir -p #{remote_dir}")
          ssh.scp.upload! "tmp/#{asset.write_path}", remote_dir
      end
  end

  def finish
    FileUtils.rm_rf 'tmp'
  end

end
