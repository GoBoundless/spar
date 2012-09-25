class LocalDeployer < Spar::Deployer

  def prepare(assets)
    super

    @deploy_path = Spar.settings['deploy_path']
    raise "ERROR: You should set the :deploy_path in your config.yml to a directory you want to do the local deploy to." unless @deploy_path
  end

  def deploy(asset)
    asset.write_to(@deploy_path)
    super
  end

end