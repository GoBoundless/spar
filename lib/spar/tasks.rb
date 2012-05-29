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
    system "/bin/rm", "-rf", App.public_path
  end
end

desc "Deploy a freshly precompiled site to S3 and purge CloudFront as is appropriate."
task :deploy => "assets:precompile" do
  Spar::Deployer.new(App).deploy
end
