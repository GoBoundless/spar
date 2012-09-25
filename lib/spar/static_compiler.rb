require 'fileutils'

module Spar
  module StaticCompiler

    HEADER_PATTERN = /
      \A (
        (?m:\s*) (
          (\/\* (?m:.*?) \*\/) |
          (\#\#\# (?m:.*?) \#\#\#) |
          (\/\/ .* \n?)+ |
          (\# .* \n?)+
        )
      )+
    /x

    DIRECTIVE_PATTERN = /
      ^ \W* = \s* (\w+.*?) (\*\/)? $
    /x

    def self.compile
      Spar.sprockets # this loads the config
      system "/bin/rm", "-rf", "#{Spar.root}/public/compiled"
      manifest = {}
      Spar.sprockets.each_logical_path do |logical_path|
        next unless compilation_info = path_compilation_info(logical_path)
        if asset = Spar.sprockets.find_asset(logical_path)
          manifest[write_asset(asset, compilation_info['digest'])] = {
            :logical_path => logical_path,
            :cache => compilation_info['cache']
          }
        end
      end
      write_manifest(manifest)
    end

    def self.write_manifest(manifest)
      FileUtils.mkdir_p("#{Spar.root}/public/compiled")
      File.open("#{Spar.root}/public/compiled/manifest.yml", 'wb') do |f|
        YAML.dump(manifest, f)
      end
    end

    def self.write_asset(asset, digest)
      path_for(asset, digest).tap do |path|
        filename = File.join("#{Spar.root}/public/compiled", path)
        FileUtils.mkdir_p File.dirname(filename)
        asset.write_to(filename)
      end
    end

    def self.path_compilation_info(logical_path)
      if logical_path =~ /\.html/
        return {
          'digest' => false, 
          'cache'  => 'no-cache'
        }
      elsif logical_path =~ /\w+\.(?!js|css).+/
        return {
          'digest' => Spar.settings['digests'], 
          'cache'  => 'no-cache'
        }
      elsif file_path = Spar.sprockets.resolve(logical_path)
        file = File.open(file_path, "rb").read
        if header = file[HEADER_PATTERN, 0]
          if directive = header.lines.peek[DIRECTIVE_PATTERN, 1]
            name, *args = Shellwords.shellwords(directive)
            if name == 'compile'
              return compilation_info(*args)
            end
          end
        end
      end
      nil
    end

    def self.compilation_info(*args)
      options = {}
      args.each do |arg| 
        options[arg.split(':')[0]] = arg.split(':')[1]
      end
      {
        'digest' => Spar.settings['digests'],
        'cache'  => options['cache'] || Spar.settings['cache_control'] || "public, max-age=#{60 * 60 * 24 * 7}"
      }
    end

    def self.path_for(asset, digest)
      if digest
        asset.digest_path
      else
        if asset.logical_path =~ /\.html$/ && !(asset.logical_path =~ /\/?index\.html$/)
          asset.logical_path.gsub(/\.html/, '/index.html')
        else
          asset.logical_path
        end
      end
    end
  end
end
