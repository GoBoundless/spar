require 'bundler'
Bundler.require

class App < Spar::Base

  register Spar::Assets
  
  get "/" do
    haml :index
  end

end