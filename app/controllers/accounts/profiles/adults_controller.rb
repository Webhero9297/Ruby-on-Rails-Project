# encoding: UTF-8
class Accounts::Profiles::AdultsController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'
  #before_filter :check_subscription
  
  def index
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @adult = Adult.new()
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def new
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @adult = Adult.new()
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def edit
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @adult = @account.profile.adults.find(params[:id])
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def create
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    
    @adult = @profile.adults.new(
      occupation: params[:adult][:occupation]
    )
    
    respond_to do |format|
      if @adult.save then
        @profile.propagate_number_of_adults()
        format.html { redirect_to(action: "index") }
        format.js
      else
        format.html { render( action: "index" )}
        format.js { render( action: "new" )}
      end
    end
  end
  
  
  def update
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @adult = @account.profile.adults.find(params[:id])
    
    respond_to do |format|
      if @adult.update_attributes(adult_params)
        @profile.propagate_number_of_adults()
        format.html { redirect_to(action: "index") }
        format.js
      else
        format.html { render( action: "edit" )}
        format.js { render( action: "edit" )}
      end
    end
  end
  
  
  def destroy
    
    @adult_id = params[:id]
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    # Make sure we always keep one adult. Based on BD business rules.
    if @profile.adults.count > 1
      @profile.adults.destroy_all(conditions: { id: @adult_id })
    end

    @profile.propagate_number_of_adults()
    
    respond_to do |format|
      format.js
    end
  end
  
  
  
  def cancel
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    
    respond_to do |format|
      format.js
    end
  end

  

private
  
  def adult_params
    params.require(:adult).permit(:occupation)
  end
end