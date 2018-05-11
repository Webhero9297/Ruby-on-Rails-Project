# encoding: UTF-8
class NewslettersController < ApplicationController
  
  filter_access_to :all
  layout 'application'
  
  def index
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def new
    
    @newsletter = Newsletter.new
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def create
    
    user = nil
    if user_signed_in? then
      user = current_user
    end
    
    @newsletter = Newsletter.create_newsletter(user, params[:newsletter], request)
    
    respond_to do |format|
      if @newsletter.valid? then
        @newsletter.save
        NotificationMailer.newsletter_subscription(@newsletter).deliver
        format.html { redirect_to(action: :index)}
      else
        format.html { render action: :new }
      end
      
    end
  end
  
  
  def activation
    
    @activation = Newsletter.activate(params[:activation_code])
    
    respond_to do |format|
      format.html
    end
  end
  
end
