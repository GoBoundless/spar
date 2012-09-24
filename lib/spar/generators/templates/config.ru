require './config/application'
require 'rack-livereload'

map "/assets" do
  run App.asset_env
end

map "/" do
  # Need to add if :development. Not sure what the right way is. Spar.environment or something? -EF
  use Rack::LiveReload  
  run App
end