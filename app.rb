# Set up for the application and database. DO NOT CHANGE. #############################
require "sinatra"                                                                     #
require "sinatra/reloader" if development?                                            #
require "sequel"                                                                      #
require "logger"                                                                      #
require "twilio-ruby"   
require "geocoder"                                                              #
require "bcrypt"                                                                     #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB ||= Sequel.connect(connection_string)                                              #
DB.loggers << Logger.new($stdout) unless DB.loggers.size > 0                          #
def view(template); erb template.to_sym; end                                          #
use Rack::Session::Cookie, key: 'rack.session', path: '/', secret: 'secret'           #
before { puts; puts "--------------- NEW REQUEST ---------------"; puts }             #
after { puts; }                                                                       #
#######################################################################################

tourist_locations_table = DB.from(:tourist_locations)
reviews_table = DB.from(:reviews)
users_table = DB.from(:users)

get "/" do 
    @tourist_locations = tourist_locations_table.all.to_a
    pp @tourist_locations 
    view "touristlocations"
end 

get "/touristlocations/:id" do 
    puts "params: #{params}"

    @tourist_location = tourist_locations_table.where(id: params[:id]).to_a[0]
    location_name = @tourist_location[:location_name]
    results = Geocoder.search(location_name)
    lat_lng = results.first.coordinates
    @lat = lat_lng[0]
    @lng = lat_lng [1]

    pp @tourist_location
    @reviews = reviews_table.where(tourist_locations_id: @tourist_location[:id]).to_a

    view "touristlocation"
end 

get "/touristlocations/:id/reviews/new" do
    
    @tourist_location = tourist_locations_table.where(id: params[:id]).to_a[0]
    view "newreview"
end 