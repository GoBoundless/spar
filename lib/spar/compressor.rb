module Spar
  module Compressor
    class JS
      def compress(source, options = {})
        require 'uglifier'
        Uglifier.compile(source, options.merge(Spar.settings['js_compressor']))
      end
    end

    class CSS
      def compress(source, options = {})
        require 'yui/compressor'
        compressor = YUI::CssCompressor.new(options.merge(Spar.settings['css_compressor']))
        compressor.compress(source)
      end
    end
  end
end