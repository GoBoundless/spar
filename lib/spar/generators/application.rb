require 'thor'

module Spar
  module Generators
  	class Error < Thor::Error
    end

    class Application < Thor
      include Thor::Actions

      source_root File.expand_path("../", __FILE__)

      desc "new APP_NAME", "create a new Spar app"
      def generate(name)
        directory 'templates', name
        inside name do
          run('chmod +x script/*')
          empty_directory_with_gitkeep "public"
          empty_directory "lib"
          empty_directory_with_gitkeep "lib/tasks"
          empty_directory_with_gitkeep "lib/assets"
          empty_directory_with_gitkeep "app/assets/images"
          empty_directory_with_gitkeep "vendor/assets/javascripts"
          empty_directory_with_gitkeep "vendor/assets/stylesheets"
        end
        puts "A new Spar app has been created in #{name} - Have Fun!"
      end

      protected

        def empty_directory_with_gitkeep(destination)
          empty_directory(destination)
          git_keep(destination)
        end

        def git_keep(destination)
          create_file("#{destination}/.gitkeep")
        end

   	end
  end
end