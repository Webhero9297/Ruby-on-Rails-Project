# encoding: utf-8
class Member::FeedbacksController < Base::BaseFeedbackController
  filter_access_to :all
  layout 'dashboard'
  before_filter :check_subscription

  def new
    super
    @url = member_feedbacks_url
    respond_to do |format|
      format.html
    end
  end

  def create
    super
    @url = member_feedbacks_url

    respond_to do |format|
      if @feedback.valid?
        @feedback.save
        Feedback.notify_admins_and_agents(@feedback)
        format.html { redirect_to thank_you_member_feedback_url(@feedback), notice: t('alert.thanks_for_feedback') }
      else
        format.html { render action: 'new', alert: 'Maybe you misstyped something? Please see the form errors.'}
      end
    end
  end

  def thank_you
    super

    respond_to do |format|
      format.html
    end
  end
end
