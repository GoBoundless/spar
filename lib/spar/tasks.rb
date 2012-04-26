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
    rm_rf public_asset_path, :secure => true
  end
end