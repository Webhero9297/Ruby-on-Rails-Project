# encoding: UTF-8
class Agent::ContactMessagesController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'
  
  def new
    
    country = current_user.account.country_short
    @national_representative = User.get_agent_profiles_for_country(country)
    @conversation = Conversation.new
    
    respond_to do |format| 
      format.html
    end
  end
  
  
  def create
    
    begin
      participants = []
      params[:member_accounts].each do |account_id|
        if Account.exists?(conditions: { id: account_id })
          participants.push(BSON::ObjectId(account_id))
        end
      end
    rescue
    end
    
    country = current_user.account.country_short
    @national_representative = User.get_agent_profiles_for_country(country)
    @national_representative.each do |rep|
      participants.push(rep.account.id)
    end
    participants.uniq!
    
    @conversation = Conversation.create_contact_message(params, participants, current_user)
    @body = params[:message][:body]
    
    respond_to do |format|
      if @conversation.save
        if current_user.is_agent
          format.html { redirect_to agent_feedbacks_path, notice: t('alert.message_sent') }
        else
          format.html { redirect_to member_dashboard_path, notice: t('alert.message_sent') }
        end
      else
        format.html { render action: "new" }
      end
    end
  end
  
end
