module Spar
  class Deployer

    def run(assets)
      prepare(assets)
      @assets_to_deploy.each { |asset| deploy(asset) }
      finish
    end

    def prepare(assets)
      @assets_to_deploy = assets
      @deployed_assets  = []
    end

    def deploy(asset)
      @deployed_assets << asset
    end

    def finish
      @deployed_assets.each do |asset|
        puts "Deployed Asset: #{asset.write_path}"
      end
    end

  end
end