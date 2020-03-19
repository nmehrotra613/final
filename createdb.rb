# Set up for the application and database. DO NOT CHANGE. #############################
require "sequel"                                                                      #
connection_string = ENV['DATABASE_URL'] || "sqlite://#{Dir.pwd}/development.sqlite3"  #
DB = Sequel.connect(connection_string)                                                #
#######################################################################################

# Database schema - this should reflect your domain model

DB.create_table! :tourist_locations do
  primary_key :id
  String :location_name
  String :description, text: true 
  String :top_things, text: true
end

DB.create_table! :reviews do
  primary_key :id
  foreign_key :tourist_locations_id
  foreign_key :user_id 
  String :hidden_gem
  String :top_place
  String :tourist_trap 
  String :travel_style
  String :comments, text: true
end

  DB.create_table! :user do 
    primary_key :id 
    String :name 
    String :email 
    String :passowrd 
end

# Insert initial (seed) data
tourist_locations_table = DB.from(:tourist_locations)

tourist_locations_table.insert(location_name: "New Orleans", 
                    description: "New Orleans is world-renowned for its distinct music, Creole cuisine, unique dialect, and its annual celebrations and festivals, most notably Mardi Gras.",
                    top_things: "French Quarter, Bourbon Street, Jackson Square")
                 
tourist_locations_table.insert(location_name: "Nashville", 
                    description: "Nashville is the capital of the U.S. state of Tennessee. It is located on the Cumberland River in Davidson County. Nicknamed 'Music City, U.S.A.', Nashville is the home of the Grand Ole Opry, the Country Music Hall of Fame, and many major record labels.",
                    top_things: "Grand Ole Opry, Country Music Hall of Fame, The Parthenon") 
                   
