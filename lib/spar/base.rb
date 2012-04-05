require 'rbconfig'
require 'sinatra/base'
require 'haml'

module Spar
  class Base < Sinatra::Base

    class << self

      attr_accessor :setup_block

      def inherited(base)
        super
        
        find_root

        set :environment,   (ENV['RACK_ENV'] || :development).to_sym
        set :root,          File.join(Spar.root, 'app')
        set :public_path,   File.join(Spar.root, 'public')
        set :library_path,  File.join(Spar.root, 'lib')

        Dir[File.join(library_path, '*.rb')].each {|file| autoload file }

        puts "Started Spar Server [#{environment.to_s}]"
      end

      protected

        def find_root
          Spar.root = begin
            # Remove the line number from backtraces making sure we don't leave anything behind
            call_stack = caller.map { |p| p.sub(/:\d+.*/, '') }
            root_path = File.dirname(call_stack.detect { |p| p !~ %r[[\w.-]*/lib/spar|rack[\w.-]*/lib/rack] })

            while root_path && File.directory?(root_path) && !File.exist?("#{root_path}/config.ru")
              parent = File.dirname(root_path)
              root_path = parent != root_path && parent
            end

            root = File.exist?("#{root_path}/config.ru") ? root_path : Dir.pwd
            raise "Could not find root path for #{self}" unless root

            RbConfig::CONFIG['host_os'] =~ /mswin|mingw/ ? Pathname.new(root).expand_path : Pathname.new(root).realpath
          end
        end

    end

  end
end