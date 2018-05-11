# encoding: UTF-8
class Accounts::Profiles::PetsController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'
  #before_filter :check_subscription
  
  def index
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @pet = Pet.new()
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def new
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @pet = @profile.pets.new()
    
    respond_to do |format|
      format.js
    end
  end
  
  
  def create
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @pet = @profile.pets.build(pets_params)
    
    respond_to do |format|
      if @pet.save then
        @profile.propagate_number_of_pets()
        format.html { redirect_to(action: "index") }
        format.js
      else
        format.html { render( action: "index" )}
        format.js { render( action: "new" )}
      end
    end
  end
  
  
  def edit
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @pet = @account.profile.pets.find(params[:id])
    
    respond_to do |format|
      format.js
    end
    
  end
  
  
  def update
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @pet = @account.profile.pets.find(params[:id])
    
    respond_to do |format|
      if @pet.update_attributes(pets_params)
        @profile.propagate_number_of_pets()
        format.html { redirect_to(account_profiles_pets_url(@account), notice: t('alert.family_profile_updated')) }
        format.js
      else
        format.html { render action: "index" }
        format.js { render action: "edit" }
      end
    end
    
  end
  
  
  def destroy
    
    @pet_id = params[:id]
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile.pets.destroy_all(conditions: { id: @pet_id })
    @profile.propagate_number_of_pets()
    respond_to do |format|
      format.js
    end
  end
  
  
  def cancel
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @pet = @account.profile.pets.find(params[:id])
    
    respond_to do |format|
      format.js
    end
  end


private
  
  def pets_params
    params.require(:pet).permit(:kind)
  end

end