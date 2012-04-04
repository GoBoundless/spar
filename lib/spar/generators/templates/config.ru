require './config/app'

map "/assets" do
  run App.assets[:env]
end

map "/" do
  run App
end