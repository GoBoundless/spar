require 'bundler'
Bundler.require

class App < Spar::Base

  get "/" do
    haml :index
  end

end