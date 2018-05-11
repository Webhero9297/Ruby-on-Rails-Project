# encoding: UTF-8
class Agent::ConversationsController < ConversationsController
  filter_access_to :all
  layout 'management'
  before_filter :check_subscription
  before_filter lambda{ set_dashboard_scope('agent') }

  def index


    if params[:q].blank?
      @conversations = Conversation.get_agent_conversations(params, current_user)
    else
      @conversations = Conversation.find_agent_conversations(params, current_user)
    end

    @participants = Conversation.get_participants(@conversations)
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def show
  	super
    @return_url = @form_url = agent_contact_messages_url
  end

  def archive_index
    if params[:q].blank?
      @conversations = Conversation.get_agent_conversations(params, current_user, true)
    else
      @conversations = Conversation.find_agent_conversations(params, current_user, true)
    end
    @participants = Conversation.get_participants(@conversations)

  end
  
  
end
