require 'sinatra'
require 'data_mapper'
require 'haml'
require 'pg'

DataMapper.setup(:default, ENV['DATABASE_URL'] || "postgres://user:password@localhost/ski_db")


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

	def protected!
		return if authorized?
		headers['WWW-Authenticate'] = 'basic realm="Restricted Area"'
		halt 401, "Not authorized\n"
	end

	def authorized?
		@auth ||=  Rack::Auth::Basic::Request.new(request.env)
	    @auth.provided? and @auth.basic? and @auth.credentials and @auth.credentials == ['admin', 'Snow!']
	end

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

get '/admin' do
	protected!	
	@areas = Area.all(:order => :name.desc) #this should sort by name alphabetically?
	@title = "Ski Areas"
	@today = Date.today
	@now = Time.now.hour
	haml :admin
end

get '/:id' do
	protected!	
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
	protected!	
	@note = Note.get params[:id]
	@title = "confirm deletion of note ##{params[:id]}"
	haml :delete_note
end

delete '/:id' do
	n = Note.get params[:id]
	n.destroy
	redirect '/admin'
end

get '/area/new' do
	protected!	
	@area = Area.new
	@title = "New Area"
	haml :edit_area
end

get '/area/:id' do
	protected!	
	@area = Area.get params[:id]
	@title = "Edit Area \'#{@area.name}\'"
	haml :edit_area
end

put '/area/:id' do
	a = Area.get params[:id]
	if a.update(name: params[:name], location: params[:location], description: params[:description])
		redirect '/admin'
	else
		haml :edit_area
	end
end

put '/area/' do
	if Area.create(name: params[:name], location: params[:location], description: params[:description])
		redirect '/admin'
	else
		haml :edit_area
	end
end

get '/area/:id/delete' do
	protected!	
	@area = Area.get params[:id]
	@title = "confirm deletion of area ##{params[:id]}"
	haml :delete_area
end

delete '/area/:id' do
	a = Area.get params[:id]
	a.destroy
	redirect '/admin'
end











