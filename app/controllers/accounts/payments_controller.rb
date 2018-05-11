# encoding: UTF-8
class Accounts::PaymentsController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'
  #before_filter :check_subscription
  
  def index
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @subscription = @account.current_subscription
    @subscriptions = @account.subscriptions.where(active: false).order_by([:created_at, :desc])
    @orders = @account.orders#Order.where(account_id: @account.id)
    @order = Order.find(@subscription.order_id)
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def show
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @subscription = @account.get_subscription(params[:id])
    @subscriptions = @account.subscriptions.where(active: false).order_by([:created_at, :desc])
    @order = Order.find(@subscription.order_id)

    respond_to do |format|
      format.html
      format.js
    end
  end
  
end
