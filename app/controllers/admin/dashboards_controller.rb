# encoding: UTF-8
class Admin::DashboardsController < ApplicationController
  filter_access_to :all
  before_filter { |c| c.set_dashboard_scope 'admin' }
  layout "dashboard"
  
  def index
    @feedbacks_url = admin_feedbacks_url
    @unread_messages = Conversation.where(participants: current_user.account.id).not_in(archived: [current_user.account.id]).not_in(read_by: [current_user.account.id]).count
  end
  
end
