# encoding: UTF-8
class Accounts::Profiles::ChildrenController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'
  #before_filter :check_subscription
  
  def index
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def new
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @child = @profile.children.new
    
    respond_to do |format|
      format.js
    end
  end
  
  
  def edit
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @child = @profile.children.find(params[:id])
    
    respond_to do |format|
      format.js
    end
  end
  
  
  def create
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @child = @profile.children.build(children_params)
    
    respond_to do |format|
      if @child.save
        @profile.propagate_number_of_children()
        format.html { redirect_to(account_profiles_children_url(@account), notice: t('alert.children_information_updated')) }
        format.js
      else
        format.html { render action: "index" }
        format.js { render action: "new"}
      end
    end
  end
  
  
  def update
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @child = @profile.children.find(params[:id])
    
    respond_to do |format|
      if @child.update_attributes(children_params)
        @profile.propagate_number_of_children()
        format.html { redirect_to(account_profiles_children_url(@account), notice: t('alert.children_information_updated')) }
        format.js
      else
        format.html { render action: "index" }
        format.js { render action: "edit"}
      end
    end
  end
  
  
  def destroy
    
    @child_id = params[:id]
    @account = Account.has_permission(current_user).find(params[:account_id])
    @profile = @account.profile
    @profile.children.destroy_all(conditions: { id: @child_id })
    @profile.propagate_number_of_children()
    respond_to do |format|
      format.js
    end
  end
  
  
  def cancel
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @child = @account.profile.children.find(params[:id])
    
    respond_to do |format|
      format.js
    end
  end


private
  
  def children_params
    params.require(:person).permit(:yob, :gender)
  end
  
end