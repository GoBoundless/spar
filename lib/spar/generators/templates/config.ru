require './config/application'

map "/assets" do
  run App.assets[:env]
end

map "/" do
  run App
end