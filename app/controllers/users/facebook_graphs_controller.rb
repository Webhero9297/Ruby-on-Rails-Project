# encoding: UTF-8
class Users::FacebookGraphsController < ApplicationController
  
  #filter_access_to :all
  layout 'dashboard'
  
  def connect
    # Setup the oAuth object
    oauth = Koala::Facebook::OAuth.new(FACEBOOK_GRAPH['app_id'], FACEBOOK_GRAPH['app_secret'], link_account_facebook_graph_url)
    # Redirect to Facebook to get the auth code and then get redirected back to the callback url.
    respond_to do |format|
      format.html { redirect_to(oauth.url_for_oauth_code)}
    end
  end
  
  
  def link_account

    if params[:code].blank?
      redirect_to(action: 'user_denied')
      return
    end
    
    # Setup the oAuth object
    oauth = Koala::Facebook::OAuth.new(FACEBOOK_GRAPH['app_id'], FACEBOOK_GRAPH['app_secret'], link_account_facebook_graph_url)
    # Fetch the access token from Facebook by grabbing the auth code and make request.
    fb_graph_token = oauth.get_access_token(params[:code])

    # Setup the graph object
    graph = Koala::Facebook::API.new(fb_graph_token)
    # Get the users 
    profile = graph.get_object("me")
    
    current_user.link_user_to_facebook(profile['id'])
    
    respond_to do |format|
      format.html {redirect_to(user_url, :notice => 'You are now connected to Facebook!')}
    end
  end


  def user_denied
    
    respond_to do |format|
      format.html
    end
  end
  
end