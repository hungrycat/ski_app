require "rubygems"
require "bundler/setup"
require "sinatra"
require "haml"
require "ski_source"

set :run, false
set :raise_errors, true

run Sinatra::Application