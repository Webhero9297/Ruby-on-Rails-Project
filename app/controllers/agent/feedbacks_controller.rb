# encoding: UTF-8
class Agent::FeedbacksController < Base::BaseFeedbackController
  filter_access_to :all
  layout "dashboard"
  
  def index
    super
    @feedbacks = []
    if not current_user.agent_profile.agent_for.empty?
      @feedbacks = Feedback.for_agent(current_user.agent_profile.agent_for).order_by(:created_at, :desc)
    end
    
    respond_to do |format|
      format.html
    end
  end
  
  
  def show
    super

    if @feedback.as_guest == false and not @feedback.account_id.blank?
      account = Account.where(_id: @feedback.account_id).first
      listing = account.listings.first if account
      @listing = listing if listing
    end
    @form_url = agent_contact_messages_url
    respond_to do |format|
      format.html
    end
  end
  
end
