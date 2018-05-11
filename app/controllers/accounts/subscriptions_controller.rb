# encoding: UTF-8
class Accounts::SubscriptionsController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'
  
  def edit
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @subscription = @account.subscriptions.find(params[:id])
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def update
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @subscription = @account.subscriptions.find(params[:id])
    
    @subscription.prolong(params[:subscription][:expires_at])
    @account.remove_restrictions_for_users
    
    respond_to do |format|
      format.html {redirect_to(account_path(@account), notice: t('alert.membership_extended')) }
    end
  end
  
end
