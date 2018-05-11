# encoding: utf-8
class FeedbacksController < Base::BaseFeedbackController
  include Rack::Recaptcha::Helpers
  filter_access_to :all
  layout 'application'

  def new
    super
    @url = feedbacks_url
    respond_to do |format|
      format.html
    end
  end

  def create
    super
    @url = feedbacks_url

    @captcha_label = nil
    if not recaptcha_valid?
      @captcha_label = 'You did not enter the words correct, please try again'
    end

    respond_to do |format|
      if @feedback.valid? and (current_user || recaptcha_valid?)
        @feedback.save
        Feedback.notify_admins_and_agents(@feedback)
        format.html { redirect_to thank_you_feedback_url(@feedback), notice: t('alert.thanks_for_feedback') }
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
