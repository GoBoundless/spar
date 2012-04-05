namespace :assets do
  desc "Compile all the assets"
  task :precompile => :clean do
    target   = File.join(App.public_path, App.asset_prefix)
    compiler = Spar::StaticCompiler.new(App.asset_env, target, App.asset_precomile,
      :manifest_path => target,
      :digest => App.asset_digests,
      :manifest => App.asset_digests
    )
    compiler.compile
  end

  desc "Remove compiled assets"
  task :clean => :environment do
    public_asset_path = File.join(App.public_path, App.asset_prefix)
    rm_rf public_asset_path, :secure => true
  end
end