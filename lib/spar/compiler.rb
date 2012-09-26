require 'fileutils'
require 'find'

module Spar
  module Compiler

    def self.assets
      assets = []
      Spar.sprockets.each_logical_path do |logical_path|
        next unless compile_info = path_compile_info(logical_path)
        if asset = Spar.sprockets.find_asset(logical_path)
          assets << Spar::CompiledAsset.new(asset, compile_info)
        end
      end
      Dir.chdir(Spar.root) do
        if Dir.exists?('static')
          Find.find('static').each do |path|
            if FileTest.directory?(path)
              if File.basename(path)[0] == '..'
                Find.prune # Don't look any further into this directory.
              else
                next
              end
            else
              if File.basename(path) == '.DS_Store'
                next
              else
                assets << Spar::CompiledAsset.new(path)
              end
            end
          end
        end
      end
      assets
    end

    def self.path_compile_info(logical_path)
      if logical_path =~ /\.html/
        return {
          :digest         => false, 
          :cache_control  => 'no-cache'
        }
      elsif logical_path =~ /\w+\.(?!js|css).+/
        return {
          :digest         => Spar.settings['digest'], 
          :cache_control  => Spar.settings['cache_control']
        }
      elsif file_path = Spar.sprockets.resolve(logical_path)
        file = File.open(file_path, "rb").read
        if header = file[Sprockets::DirectiveProcessor::HEADER_PATTERN, 0]
          header.lines.each do |header|
            if directive = header[Sprockets::DirectiveProcessor::DIRECTIVE_PATTERN, 1]
              name, *args = Shellwords.shellwords(directive)
              if name == 'deploy'
                return deploy_directive_info(*args)
              end
            end
          end
        end
      end
      nil
    end

    def self.deploy_directive_info(*args)
      options = {}
      args.each do |arg| 
        options[arg.split(':')[0]] = arg.split(':')[1]
      end
      {
        :digest         => Spar.settings['digest'],
        :cache_control  => options['cache_control'] || Spar.settings['cache_control']
      }
    end

  end
end
