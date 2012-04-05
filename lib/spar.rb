module Spar
  autoload :Version, 'spar/version'
  autoload :Base, 'spar/base'
  autoload :Assets, 'spar/assets'

  class << self

    attr_accessor :root, :assets

  end

end
