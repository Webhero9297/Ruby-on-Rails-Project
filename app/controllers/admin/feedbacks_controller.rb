# encoding: utf-8
class Admin::FeedbacksController < Base::BaseFeedbackController
  filter_access_to :all
  layout "management"
  
  def index
    super
    
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
    @form_url = admin_contact_messages_url
    respond_to do |format|
      format.html
    end
  end
  
end
