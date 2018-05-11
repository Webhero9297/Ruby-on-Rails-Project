# encoding: utf-8
class ExchangeFeedbacksController < ApplicationController
  filter_access_to :all
  layout 'management'

  ##
  #
  def positive_index
    @feedbacks = []
    exchange_feedbacks = ExchangeFeedback.any_of({ recommend: true }).where(:answered => true).order_by([:updated_at, :desc])

    if agent_session?
      countries = current_user.agent_profile.get_assigned_countries_short_codes
      exchange_feedbacks = exchange_feedbacks.any_in(:agent_countries => countries)
    end

    exchange_feedbacks.each do |feedback|
      begin
        exchange_agreement = ExchangeAgreement.find(feedback.exchange_agreement_id)
        answered_on_agreement = exchange_agreement.agreements.where(:owner => feedback.feedback_on_account).first
        next if answered_on_agreement.nil?
        answered_by_agreement = exchange_agreement.agreements.where(:owner => feedback.answered_by_account).first
        next if answered_by_agreement.nil?
        @feedbacks.push({:feedback => feedback, :answered_on_agreement => answered_on_agreement, :answered_by_agreement => answered_by_agreement})
      rescue Exception => e
      end
    end

    respond_to do |format|
      format.html
    end
  end


  ##
  #
  def negative_index
    @feedbacks = []
    exchange_feedbacks = ExchangeFeedback.any_of({ recommend: false }, { expectations: "below" }).where(:answered => true).order_by([:updated_at, :desc])

    if agent_session?
      countries = current_user.agent_profile.get_assigned_countries_short_codes
      exchange_feedbacks = exchange_feedbacks.any_in(:agent_countries => countries)
    end

    exchange_feedbacks.each do |feedback|
      begin
        exchange_agreement = ExchangeAgreement.find(feedback.exchange_agreement_id)
        answered_on_agreement = exchange_agreement.agreements.where(:owner => feedback.feedback_on_account).first
        next if answered_on_agreement.nil?
        answered_by_agreement = exchange_agreement.agreements.where(:owner => feedback.answered_by_account).first
        next if answered_by_agreement.nil?
        @feedbacks.push({:feedback => feedback, :answered_on_agreement => answered_on_agreement, :answered_by_agreement => answered_by_agreement})
      rescue Exception => e
      end
    end

    respond_to do |format|
      format.html
    end
  end


  def show
    @exchange_feedback = ExchangeFeedback.find(params[:id])
    @feedback_on_account = Account.find(@exchange_feedback.feedback_on_account)
    @answered_by = Account.find(@exchange_feedback.answered_by_account)

    exchange_agreement = ExchangeAgreement.find(@exchange_feedback.exchange_agreement_id)

    @answered_on_agreement = exchange_agreement.agreements.where(:owner => @exchange_feedback.feedback_on_account).first
    @answered_by_agreement = exchange_agreement.agreements.where(:owner => @exchange_feedback.answered_by_account).first

    respond_to do |format|
      format.html
    end
  end


  def edit
    current_user.reset_authentication_token!
    @exchange_feedback = ExchangeFeedback.find(params[:id])
    @exchange_feedback.set_viewed_at()
    
    @exchange_agreement = ExchangeAgreement.find(@exchange_feedback.exchange_agreement_id)
    partner_id = @exchange_agreement.get_partner_account_id(current_user.account.id)
    @exchange_partner = Account.find(partner_id)
    @partner_agreement = @exchange_agreement.agreements.where(owner: partner_id).first

    #NotificationMailer.negative_exchange_feedback(@exchange_feedback, @member_agreement, @partner_agreement, agent.email).deliver
    
    respond_to do |format|
      format.html {render(layout: 'dashboard')}
    end
  end
  
  
  def update
    
    @exchange_feedback = ExchangeFeedback.find(params[:id])
    @exchange_feedback = @exchange_feedback.populate_feedback_form(params[:exchange_feedback])

    @exchange_agreement = ExchangeAgreement.find(@exchange_feedback.exchange_agreement_id)
    partner_id = @exchange_agreement.get_partner_account_id(current_user.account.id)

    @member_agreement = @exchange_agreement.agreements.where(owner: current_user.account_id).first

    @exchange_partner = Account.find(partner_id)
    @partner_agreement = @exchange_agreement.agreements.where(owner: partner_id).first
    
    respond_to do |format|
      if @exchange_feedback.valid?
        @exchange_feedback.save
        
        if @exchange_feedback.recommend == false or @exchange_feedback.expectations == 'below'
          agent_profiles = []
          
          @exchange_feedback.agent_countries.each do |agent_country|
            agent_profiles = User.get_agent_profiles_for_country(agent_country)
            agent_profiles.each do |agent|
              NotificationMailer.negative_exchange_feedback(@exchange_feedback, @member_agreement, @partner_agreement, agent.email).deliver
            end
          end

          NotificationMailer.negative_exchange_feedback(@exchange_feedback, @member_agreement, @partner_agreement, 'the-board@intervac.org').deliver
        end
        
        format.html {redirect_to(action: "thank_you")}
      else
        format.html {render( action: :edit )}
      end
    end
  end
  
  
  def thank_you
    
    respond_to do |format|
      format.html {render(layout: 'dashboard')}
    end
  end
  
end
