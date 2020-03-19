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

before do
    @current_user = users_table.where(id: session["user_id"]).to_a[0]
end

get "/" do 
    @tourist_locations = tourist_locations_table.all.to_a
    pp @tourist_locations 
    view "touristlocations"
end 

get "/touristlocations/:id" do 
    puts "params: #{params}"
    @tourist_location = tourist_locations_table.where(id: params[:id]).to_a[0]
    @users_table = users_table
    location_name = @tourist_location[:location_name]
    results = Geocoder.search(location_name)
    lat_lng = results.first.coordinates
    @lat = lat_lng[0]
    @lng = lat_lng [1]

    pp @tourist_location

    if params[:travel_style] != nil
        if params[:travel_style] != nil 
            @reviews = reviews_table.where(travel_style: params[:travel_style]).to_a
        end 
    else
        @reviews = reviews_table.where(tourist_locations_id: @tourist_location[:id]).to_a
    end 
    
    if @current_user
        @review_count = reviews_table.where(tourist_locations_id: @tourist_location[:id], user_id: @current_user[:id]).count
    end

    view "touristlocation"

end 

get "/touristlocations/:id/reviews/new" do
    @tourist_location = tourist_locations_table.where(id: params[:id]).to_a[0]
    view "newreview"
end 

post "/touristlocations/:id/reviews/create" do 
      @tourist_location = tourist_locations_table.where(id: params[:id]).to_a[0]
      reviews_table.insert(
          tourist_locations_id: @tourist_location[:id],
          user_id: session["user_id"],
          age: params["age"],
          travel_with: params["travel_with"],
          travel_style: params["travel_style"],
          top_place: params["top_place"],
          hidden_gem: params["hidden_gem"],
          tourist_trap: params["tourist_trap"],
          top_restaurant: params["top_restaurant"],
          comments: params["comments"]
      )
        redirect "/touristlocations/#{@tourist_location[:id]}"
end 

get "/reviews/:id/edit" do
    puts "params: #{params}"
    @review = reviews_table.where(id: params["id"]).to_a[0]
    @tourist_location = tourist_locations_table.where(id: @review[:tourist_locations_id]).to_a[0]
    view "editreview"
end

post "/reviews/:id/update" do
    puts "params: #{params}"
    @review = reviews_table.where(id: params["id"]).to_a[0]
    # find the rsvp's event
    @tourist_location = tourist_locations_table.where(id: @review[:tourist_locations_id]).to_a[0]

    if @current_user && @current_user[:id] == @review[:user_id]
        reviews_table.where(id: params["id"]).update(
          age: params["age"],
          travel_with: params["travel_with"],
          travel_style: params["travel_style"],
          top_place: params["top_place"],
          hidden_gem: params["hidden_gem"],
          tourist_trap: params["tourist_trap"],
          top_restaurant: params["top_restaurant"],
          comments: params["comments"]
        )
        redirect "/touristlocations/#{@tourist_location[:id]}"
    else
        view "error"
    end
end

get "/reviews/:id/destroy" do
    puts "params: #{params}"
    review = reviews_table.where(id: params["id"]).to_a[0]
    @tourist_location = tourist_locations_table.where(id: review[:tourist_locations_id]).to_a[0]
    reviews_table.where(id: params["id"]).delete
    redirect "/touristlocations/#{@tourist_location[:id]}"
end

get "/users/new" do 
    puts "params: #{params}"
    view "newuser"
end

get "/users/create" do
    puts "params: #{params}"
    hashed_password = BCrypt::Password.create(params["password"])
    pp hashed_password
    users_table.insert(
        name: params["name"],
        email: params["email"], 
        password: hashed_password
    )
    view "createuser"
end

get "/logins/new" do
    view "newlogin"
end

post "/logins/create" do
    user = users_table.where(email: params["email"]).to_a[0]
    if user && BCrypt::Password::new(user[:password]) == params["password"]
        session["user_id"] = user[:id]
        view "createlogin"
    else
        view "loginfailed"
    end
end

get "/logout" do
    session["user_id"] = nil
    @current_user = nil
    view "logout"
end