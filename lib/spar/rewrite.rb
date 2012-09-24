require 'time'
require 'uri'

module Spar

  class Rewrite

    def initialize(app)
      @app = app
    end

    def call(env)

      if env['HTTP_ACCEPT'] =~ /text\/html/
        if env['PATH_INFO'] == '/'
          env['PATH_INFO'] = '/index.html'
        else
          unless env['PATH_INFO'] =~ /\.html$/
            env['PATH_INFO'] << '.html'
          end
        end
      end

      @app.call(env)
    end

  end

end