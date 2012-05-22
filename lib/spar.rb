module Spar
  autoload :Version, 'spar/version'
  autoload :Base, 'spar/base'
  autoload :Assets, 'spar/assets'
  autoload :StaticCompiler, 'spar/static_compiler'
  autoload :Helpers, 'spar/helpers'
  autoload :CssCompressor, 'spar/css_compressor'

  class << self

    attr_accessor :root, :assets

  end

end