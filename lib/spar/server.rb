require 'time'
require 'uri'

module Spar

  module Server

    def call(env)

      path = unescape(env['PATH_INFO'].to_s.sub(/^\//, ''))

    end

  end

end