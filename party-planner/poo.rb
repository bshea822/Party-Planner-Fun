require 'sinatra'
require "sinatra/reloader" if development?
require 'sinatra/flash'
require "pry" if development? || test?
require_relative 'config/application'
require "pg"

set :bind, '0.0.0.0'  # bind to all interfaces

configure do
  set :views, 'app/views'
end

enable :sessions

Dir[File.join(File.dirname(__FILE__), 'app', '**', '*.rb')].each do |file|
  require file
  also_reload file
end

def db_connection
  begin
    connection = PG.connect(dbname: "party_planner_development")
    yield(connection)
  ensure
    connection.close
  end
end

get '/' do
  redirect '/parties'
end

get '/parties/new' do
  erb :'parties/new'
end

get '/parties' do
  @parties = db_connection { |conn| conn.exec("SELECT * FROM parties") }
  erb :'parties/index'
end

get '/parties/:id' do
@parties = db_connection { |conn| conn.exec("SELECT * FROM parties") }
  @parties.each do |party|
    if party['id'] == params["id"]
      @party = party
    end
  end

  erb :'parties/show'
end



post '/parties/new' do

  @name = params['name']
  @location = params['location']
  @description = params['description']

  if @name != ""
    db_connection do |conn|
      conn.exec_params("INSERT INTO parties (name, location, description) VALUES ($1, $2, $3)", [@name, @location, @description])
    end
    redirect '/parties'
  else
    @error = "Please fill out all forms."
  end
