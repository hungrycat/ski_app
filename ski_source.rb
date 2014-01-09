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
	property :short_name, Text
	property :location, Text
	property :description, Text
	property :lat, Text
	property :lng, Text
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

#public pages

get '/' do 
	@areas = Area.all(:order => :id).reverse #this should sort by name alphabetically?
	@title = "Ski Areas"
	@recent_notes = Note.all(:limit => 4, :order => [:created_time.desc])
	@today = Date.today
	@now = Time.now.hour
	haml :home
end

#need data validation
post '/' do
	area = Area.get(params[:area])
	note = area.notes.create(content: params[:content], created_time: Time.now, created_date: Date.today)
	redirect '/' #it would be nice to be able to direct to the area the notes was posted to
end


get '/map' do
	@areas = Area.all
	@areas = @areas.delete_if{|a| a.lat.nil? || a.lng.nil?}
	@title = "Area map"
	haml :map, :layout => false
end

get '/area/:id' do
	@area = Area.get(params[:id])
	@title = @area.name
	@today = Date.today
	@now = Time.now.hour
	haml :area
end

#======================
#admin pages

get '/admin' do
	protected!	
	@areas = Area.all(:order => :id).reverse  
	@title = "Ski Areas - Admin"
	@today = Date.today
	@now = Time.now.hour
	haml :admin
end

#=================
#edit or delete notes

get '/admin/:id' do
	protected!	
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	haml :edit_note
end

put '/admin/:id' do
	n = Note.get params[:id]
	if n.update( content: params[:content], created_time:  Time.now, created_date: Date.today)
		redirect '/'
	else 
		haml :edit_note
	end
end

get '/admin/:id/delete' do
	protected!	
	@note = Note.get params[:id]
	@title = "Confirm deletion of note ##{params[:id]}"
	haml :delete_note
end

delete '/admin/:id' do
	n = Note.get params[:id]
	n.destroy
	redirect '/admin'
end


#===========================
#create, edit, destroy areas

get '/admin/area/new' do
	protected!	
	@area = Area.new
	@title = "New Area"
	haml :edit_area
end

get '/admin/area/:id' do
	protected!	
	@area = Area.get params[:id]
	@title = "Edit Area \'#{@area.name}\'"
	haml :edit_area
end

put '/admin/area/:id' do
	a = Area.get params[:id]
	if a.update(name: params[:name], short_name: params[:short_name], location: params[:location], description: params[:description], lat: params[:lat], lng: params[:lng])
		redirect '/admin'
	else
		haml :edit_area
	end
end

put '/admin/area/' do
	if Area.create(name: params[:name], location: params[:location], description: params[:description], lat: params[:lat], lng: params[:lng])
		redirect '/admin'
	else
		haml :edit_area
	end
end

get '/admin/area/:id/delete' do
	protected!	
	@area = Area.get params[:id]
	@title = "Confirm deletion of area ##{params[:id]}"
	haml :delete_area
end

delete '/admin/area/:id' do
	a = Area.get params[:id]
	a.destroy
	redirect '/admin'
end











