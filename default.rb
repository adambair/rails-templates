run "rm public/index.html"
run "rm public/images/rails.png"
run "rm README"
run "cp config/database.yml config/database.yml.example"
run "rm public/favicon.ico"
run "rm public/robots.txt"
 
file '.gitignore', <<-END
.DS_Store
log/*.log
tmp/**/*
config/database.yml
db/*.sqlite3
END
 
plugin 'asset_packager', :git => 'git://github.com/sbecker/asset_packager.git'

gem 'haml'
gem 'authlogic'

file '.testgems',
%q{config.gem 'cucumber'
config.gem 'webrat'
config.gem 'rspec', :lib => false
config.gem 'rspec-rails', :lib => false
config.gem 'thoughtbot-factory_girl', :lib => 'factory_girl', :source => 'http://gems.github.com'
config.gem 'thoughtbot-shoulda', :lib => 'shoulda', :source => 'http://gems.github.com'
config.gem 'mislav-will_paginate', :version => '~> 2.2.3', :lib => 'will_paginate', :source => 'http://gems.github.com'
config.gem 'faker', :lib => false, :version => '>=0.3.1'
config.gem 'jscruggs-metric_fu', :lib => false, :version => '>=1.1.4'
}
run 'cat .testgems >> config/environments/test.rb && rm .testgems'

run "rm public/javascripts/controls.js public/javascripts/dragdrop.js public/javascripts/effects.js public/javascripts/prototype.js"
run "curl -L http://jqueryjs.googlecode.com/files/jquery-1.3.2.min.js > public/javascripts/jquery.js"
run "curl -L http://jqueryjs.googlecode.com/svn/trunk/plugins/form/jquery.form.js > public/javascripts/jquery.form.js"

generate('rspec')
generate('cucumber')
generate('session', 'user_session')
generate('model', 'User email:string crypted_password:string password_salt:string persistence_token:string login_count:integer last_request_at:datetime last_login_at:datetime current_login_at:datetime last_login_ip:string current_login_ip:string')

file 'app/models/user.rb', <<-CODE
class User < ActiveRecord::Base
  acts_as_authentic
end
CODE

file 'app/controllers/user_sessions_controller.rb', <<-CODE
class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => :destroy
  
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Login successful!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "Logout successful!"
    redirect_back_or_default new_user_session_url
  end
end
CODE

file 'app/controllers/users_controller.rb', <<-CODE
class UsersController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:show, :edit, :update]

  def new
    @user = User.new
  end

  def create
    @user = User.new(params[:user])
    if @user.save
      flash[:notice] = "Account registered!"
      redirect_back_or_default account_url
    else
      render :action => :new
    end
  end

  def show
    @user = @current_user
  end

  def edit
    @user = @current_user
  end

  def update
    @user = @current_user # makes our views "cleaner" and more consistent
    if @user.update_attributes(params[:user])
      flash[:notice] = "Account updated!"
      redirect_to account_url
    else
      render :action => :edit
    end
  end
end
CODE

file 'app/controllers/application_controller.rb', <<-CODE
class ApplicationController < ActionController::Base
  filter_parameter_logging :password, :password_confirmation
  helper_method :current_user_session, :current_user

  private
   
  def current_user_session
    return @current_user_session if defined?(@current_user_session)
    @current_user_session = UserSession.find
  end

  def current_user
    return @current_user if defined?(@current_user)
    @current_user = current_user_session && current_user_session.user
  end

  def require_user
    unless current_user
      store_location
      flash[:notice] = "You must be logged in to access this page"
      redirect_to new_user_session_url
      return false
    end
  end

  def require_no_user
    if current_user
      store_location
      flash[:notice] = "You must be logged out to access this page"
      redirect_to account_url
      return false
    end
  end

  def store_location
    session[:return_to] = request.request_uri
  end

  def redirect_back_or_default(default)
    redirect_to(session[:return_to] || default)
    session[:return_to] = nil
  end
end
CODE

file 'app/views/users/new.html.erb', <<-CODE
<h1>Register</h1>
<%= error_messages_for :user %>

<br/>
<div class='signup_login_normal'>
  <h2>Register </h2>
  <% form_for @user, :url => account_path do |f| %>
    <%= render :partial => "form", :object => f %>
    <br/>
    <%= f.submit "Register" %>
    <%= link_to 'Cancel', login_url, :class => "button grey" %>
  <% end %>
</div>
CODE

file 'app/views/users/edit.html.erb', <<-CODE
<h1>Edit My Account</h1>

<% form_for @user, :url => account_path do |f| %>
  <%= f.error_messages %>
  <%= render :partial => "form", :object => f %>
  <%= f.submit "Update" %>
  <%= link_to "Cancel", root_path, :class => "button grey" %>
<% end %>
CODE

file 'app/views/users/_form.erb', <<-CODE
<%= form.label :login, "Login" %>
<%= form.text_field :login %>

<%= form.label :email, "E-Mail" %>
<%= form.text_field :email %>

<%= form.label :password, form.object.new_record? ? nil : "Change password" %>
<%= form.password_field :password %>

<%= form.label :password_confirmation, "Password Confirmation" %>
<%= form.password_field :password_confirmation %>
CODE

file 'app/views/users/show.html.erb', <<-CODE
<h1><%= @user.email %></h1>
<%= link_to 'Edit my account', edit_user_path(@user) %>
CODE

file 'public/javascripts/application.js', <<-CODE
jQuery.ajaxSetup({ 
    'beforeSend': function(xhr) {xhr.setRequestHeader("Accept", "text/javascript")} 
});

$(document).ready(function() {
  // if($('div.flash').length > 0) {
  // 	setTimeout("$('div.flash').hide('slide', { direction: 'up' }, 1000)", 5000);
  // }
});
CODE

file 'app/views/user_sessions/new.html.erb', <<-CODE
<h1>Login</h1>
<p>Don't have an account yet?  Why not <strong><%= link_to 'register', register_path %></strong>?</p>

<%= error_messages_for :user_session %>
<br/>

<% form_for @user_session, :url => user_session_path do |f| %>
  <%= f.label :login, "Login" %>
  <%= f.text_field :login %>
  <%= clearfix %>

  <%= f.label :password %>
  <%= f.password_field :password %>
  <%= clearfix %>

  <%= f.label :remember_me %>
  <%= f.check_box :remember_me %>

  <%= clearfix %>
  <br/>
  <%= f.submit "Sign In" %>
<% end %>
CODE

route 'map.root     :controller => "user_sessions", :action => "new"'
route 'map.logout   "/logout",   :controller => "user_sessions", :action => "destroy"'
route 'map.login    "/login",    :controller => "user_sessions", :action => "new"'
route 'map.register "/register", :controller => "users",         :action => "new"'
route 'map.resource :user_session'
route 'map.root :controller => "user_sessions", :action => "new"'
route 'map.resource :account, :controller => "users"'
route 'map.resources :users'

if yes?("Create and migrate databases now? (yes/no)")
  rake("db:create:all")
  rake("db:migrate")
end

puts "#" * 30
puts "TO-DO checklist:"
puts "\t* Write specs for the User model and controller"
puts "\t* Create views for Authlogic - see http://github.com/binarylogic/authlogic_example/tree/master/app/views for examples"
puts "\t* Generate your asset_packager config with: rake asset:packager:create_yml"
puts "#" * 30

