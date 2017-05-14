class ApplicationController < ActionController::Base
  protect_from_forgery with: :exception
  http_basic_authenticate_with :name => "admin", :password => ENV['ADMIN_PASSWORD']
end
