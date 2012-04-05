require './config/application'

map "/assets" do
  run App.asset_env
end

map "/" do
  run App
end