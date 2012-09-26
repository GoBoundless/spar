namespace :assets do
  desc "Compile all the assets to the public directory"
  task :precompile => :clean do
    puts "Precompiling Assets for environment #{Spar.environment}"
    Spar.settings['deploy_path'] = 'public'

    require "spar/deployers/local_deployer"

    LocalDeployer.new.run(Spar::Compiler.assets)
  end

  desc "Remove compiled assets"
  task :clean do
    system "/bin/rm", "-rf", 'public'
  end
end
