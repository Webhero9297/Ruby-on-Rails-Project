# encoding: UTF-8
class MembersController < ApplicationController
  filter_access_to :all
  layout "dashboard"
  before_filter :check_subscription
  
  def index
    
    @accounts = Account.order_by([:created_at, :desc]).page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def show
    
    @account = Account.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def search
    
    @account = Account.find_member_by_params(params)
    
    respond_to do |format|
      format.js
      format.json {render( json: @account )}
    end
  end
  
  
  def filter
    
    @accounts = Account.filter_members_by_params(params).page(params[:page]).per(20)
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
end
