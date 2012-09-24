require './config/application'
require 'rack-livereload'

map "/assets" do
  run App.asset_env
end

map "/" do
  use Rack::LiveReload
  run App
end