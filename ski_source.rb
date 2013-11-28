require 'sinatra'
require 'data_mapper'
require 'haml'
require "sinatra-authentication"

use Rack::Session::Cookie, :secret => 'sasafras'

DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

# each area has a name, a location (a link?), a description?, 
# and contains various notes that people have posted
class Area
	include DataMapper::Resource
	property :id, Serial
	property :name, Text, :required => true
	property :location, Text
	property :description, Text


	has n, :notes
end

# each Note belongs to an Area and contains the note text, and the date and time created
class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :created_time, DateTime
	property :created_date, Date
	belongs_to :area
end


 
DataMapper.finalize.auto_upgrade!

helpers do
	include Rack::Utils

	alias_method :h, :escape_html
end


get '/' do 
	@areas = Area.all(:order => :name.desc) #this should sort by name alphabetically?
	@title = "Ski Areas"
	@today = Date.today
	@now = Time.now.hour
	haml :home
end

#need data validation
post '/' do
	area = Area.get(params[:area])
	note = area.notes.create(content: params[:content], created_time: Time.now, created_date: Date.today)
	redirect '/' #it would be nice to be able to direct to ##{params[:name]}
end

get '/:id' do
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	haml :edit_note
end

put '/:id' do
	n = Note.get params[:id]
	if n.update( content: params[:content], created_time:  Time.now, created_date: Date.today)
		redirect '/'
	else 
		haml :edit_note
	end
end

get '/:id/delete' do
	@note = Note.get params[:id]
	@title = "confirm deletion of note ##{params[:id]}"
	haml :delete_note
end

delete '/:id' do
	n = Note.get params[:id]
	n.destroy
	redirect '/'
end

get '/area/new' do
	@area = Area.new
	@title = "New Area"
	haml :edit_area
end

get '/area/:id' do
	@area = Area.get params[:id]
	@title = "Edit Area \'#{@area.name}\'"
	haml :edit_area
end

put '/area/:id' do
	a = Area.get params[:id]
	if a.update(name: params[:name], location: params[:location], description: params[:description])
		redirect '/'
	else
		haml :edit_area
	end
end

put '/area/' do
	if Area.create(name: params[:name], location: params[:location], description: params[:description])
		redirect '/'
	else
		haml :edit_area
	end
end

get '/area/:id/delete' do
	@area = Area.get params[:id]
	@title = "confirm deletion of area ##{params[:id]}"
	haml :delete
end


get '/admin_login' do
	haml :admin_login
end

get 'admin' do
	haml :admin
end







