require 'sinatra'
require 'data_mapper'
require 'haml'

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

# each Note belongs to an Area and contains the note text, and the date created
class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :created_at, DateTime
	property :updated_at, DateTime

	belongs_to :area
end
 
DataMapper.finalize.auto_migrate!

helpers do
	include Rack::Utils

	alias_method :h, :escape_html
end


green_rock = Area.create(name: "Green Rock")
cnr = Area.create(name: "Corner Mountain and Little Laramie")
cp = Area.create(name: "Chimney Park")


get '/' do 
	@areas = Area.all #todo: add order :order => :id.desc

	@title = "Ski Areas"
	haml :home
end

post '/' do
	n = Note.new
	n.content = params[:content]
	n.complete = false
	n.created_at = Time.now
	n.updated_at = Time.now
	n.save
	redirect '/'
end

get '/:id' do
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	haml :edit
end

put '/:id' do
	n = Note.get params[:id]
	n.content = params[:content]
	n.updated_at = Time.now
	n.save
	redirect '/'
end

get '/:id/delete' do
	@note = Note.get params[:id]
	@title = "confirm deletion of note ##{params[:id]}"
	haml :delete
end

delete '/:id' do
	n = Note.get params[:id]
	n.destroy
	redirect '/'
end



