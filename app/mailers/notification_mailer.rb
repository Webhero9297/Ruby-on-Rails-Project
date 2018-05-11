# encoding: UTF-8
class NotificationMailer < ActionMailer::Base
  default from: "Intervac Notification <noreply@messaging.intervac-homeexchange.com>"

  add_template_helper(ApplicationHelper)
  include ApplicationHelper

  def added_favorite(favorite, user, listing)
    @favorite = favorite
    @user = user
    @listing = listing

    @locale = @favorite.account.get_country.default_locale
    @user_country = @user.account.get_country.msgid
    @subject = "#{t('mailer.added_as_favorite.member_from', {:COUNTRY => t(@user_country), :locale => @locale })}"

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "#{@favorite.name} <#{@favorite.email}>", :subject => @subject)
    else
      mail(:to => "#{@favorite.name} <#{@favorite.email}>", :subject => "TEST #{@subject} TEST")
    end
  end

  ##
  # Sends e-mail to the country agent
  def new_signup(agent, user, order, price_plan)
    @user = user
    @order = order
    @price_plan = price_plan

    subject = "New sign up - #{user.account.account_number} - #{user.name} - #{user.account.contact.email}"

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => subject)
    else
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => "TEST #{subject} TEST")
    end
  end

  ##
  # Sends e-mail to the country agent when a successfull payment has been done.
  def success_payment(order)
    begin
      @order = order
      @user = User.find(@order.user_id)
      @listings = @user.account.listings
      country_short = @user.account.country_short

      @country = Country.where(short: country_short).first
      @price_plan = Country.get_price_plan_by_country_and_id(country_short, @order.price_plan_id)
      agents = User.get_agent_profiles_for_country(country_short)

      subject = "Successful payment for order #{@order.order_number} - #{@user.name} - #{@user.account.contact.email}"
    rescue => e
      NotificationMailer.oddity("Success payment mail could not be sent for order: #{@order.order_number}, error:  #{e}").deliver
    end

    mail_agents = []
    if not agents.empty?
      agents.each do |agent|
        mail_agents.push("#{agent.name} <#{agent.agent_profile.email}>")
      end
    end

    mail_agents = mail_agents.join(",")
    if Rails.env.production? or Rails.env.staging? then
      mail(:to => mail_agents, :subject => subject)
    else
      mail(:to => mail_agents, :subject => "TEST #{subject} TEST")
    end
  end

  ##
  # Sends a e-mail with information to create an invoice
  def invoice_payment(agent, user, order, price_plan)
    @user = user
    @order = order
    @price_plan = price_plan
    subject = "New invoice - #{user.account.account_number} - #{user.name} - #{user.account.contact.email}"
    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => subject)
    else
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => "TEST #{subject} TEST")
    end
  end

  ##
  # Sends a e-mail with information to create an offline payment
  def offline_payment(agent, user, order, price_plan)
    @user = user
    @order = order
    @price_plan = price_plan
    subject = "New offline payment - Account: #{user.account.account_number} - #{user.name} - #{user.account.contact.email}"
    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => subject)
    else
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => "TEST #{subject} TEST")
    end
  end

  ##
  # Sends an e-mail to country agents if sign up chose a trial instead of a paid membership
  def trial_instead_of_paid(agent, user, order, original_price_plan)
    @user = user
    @order = order
    @original_price_plan = original_price_plan
    subject = "Choose trial instead of paid - #{user.account.account_number} - #{user.name} - #{user.account.contact.email}"
    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => subject)
    else
      mail(:to => "#{agent.name} <#{agent.agent_profile.email}>", :subject => "TEST #{subject} TEST")
    end
  end

  ##
  # Sends newsletter subscription confirmation.
  def newsletter_subscription(newsletter)
    @newsletter = newsletter

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "<#{@newsletter.email}>", :subject => "Intervac Home Exchange newsletter")
    else
      mail(:to => "<#{@newsletter.email}>", :subject => "TEST Intervac Home Exchange newsletter TEST")
    end
  end

  ##
  # Sends out emails with a link to the Exchange feedback
  def exchange_feedback(exchange_feedback, user)
    @user = user
    @exchange_feedback = exchange_feedback

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "<#{@user.email}>", :subject => "Welcome home!")
    else
      mail(:to => "<#{@user.email}>", :subject => "TEST Welcome home TEST")
    end
  end

  ##
  # Sends out emails with a link to the Exchange feedback
  def negative_exchange_feedback(exchange_feedback, member_agreement, partner_agreement, receiver_email)
    @exchange_feedback = exchange_feedback

    @answering_account = Account.find(@exchange_feedback.answered_by_account)
    @feedback_account = Account.find(@exchange_feedback.feedback_on_account)
    @member_agreement = member_agreement
    @partner_agreement = partner_agreement

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "<#{receiver_email}>", :subject => "Negative Exchange Feedback")
    else
      mail(:to => "<#{receiver_email}>", :subject => "TEST Negative Exchange Feedback TEST")
    end
  end

  def service_feedback(service_feedback, recv_email)
    @feedback = service_feedback
    @country  = Country.get_by_short(@feedback.country_short) || "NO COUNTRY"

    email = recv_email.is_a?(String) ? "<#{recv_email}>" : recv_email
    msg   = if Rails.env.production? or Rails.env.staging?
              "Site and Service Feedback"
            else
              "TEST Site and Service Feedback TEST"
            end

    if @feedback.email
      mail(:from => @feedback.email, :to => email, :subject => "[#{t(@country.msgid, :locale => 'en')}] | #{msg}")
    else
      mail(:to => email, :subject => "[#{t(@country.msgid, :locale => 'en')}] | #{msg}")
    end
  end

  ##
  # Welcome mail for paying users
  def welcome(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'welcome', :countries.in => [user.account.country_short]).first
      agent = @agents.first
      agent_profile = agent.agent_profile
      agent_name = agent_profile.name
      if agent_name.blank?
        agent_name = agent.name
      end
      agent_email = agent_profile.email
      if agent_email.blank?
        agent_email = agent.email
      end


      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = agent_name
      @agent_placeholders[:MY_EMAIL] = agent_email
      @agent_placeholders[:MY_PHONE] = agent_profile.telephone
      @agent_placeholders[:MY_FAX] = agent_profile.fax
      @agent_placeholders[:MY_URL] = agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'welcome', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the welcome message for user #{@user.id} and message #{@message}. Error: #{e}").deliver
      return
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.welcome.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  ##
  # Welcome mail for trial sign ups
  def welcome_trial(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'welcome_trial', :countries.in => [user.account.country_short]).first
      agent = @agents.first
      agent_profile = agent.agent_profile
      agent_name = agent_profile.name
      if agent_name.blank?
        agent_name = agent.name
      end
      agent_email = agent_profile.email
      if agent_email.blank?
        agent_email = agent.email
      end

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      @placeholders[:NUMBER] = length_of_trial_membership()

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = agent_name
      @agent_placeholders[:MY_EMAIL] = agent_email
      @agent_placeholders[:MY_PHONE] = agent_profile.telephone
      @agent_placeholders[:MY_FAX] = agent_profile.fax
      @agent_placeholders[:MY_URL] = agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'welcome_trial', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the welcome trial for user #{@user.id} and message #{@message}. Error: #{e}").deliver
      raise
      return
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.welcome_trial.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  ##
  # Sends out a match alert message
  def match_alert(account, listings)
    @listings = listings
    @account = account

    begin
      locale = @account.get_country.default_locale
    rescue
      locale = 'en'
    end

    receivers = []

    account.users.each do |user|
      receiver = {name: user.name, email:user.email}
      receivers.push(receiver)
      next if user.secondary_email.blank?
      receiver = {name: user.name, email:user.secondary_email}
      receivers.push(receiver)
    end

    receivers = receivers.collect {|u| "#{u[:name]} <#{u[:email]}>"}.join ', '

    mail(:to => receivers, :subject => t('automated_messages.new_match_alert.subject', locale: locale))
  end

  ##
  # Sends out update information about a exchange agreement
  def exchange_agreement(partner_account, owner_account, exchange_agreement)
    current_locale = I18n.locale.to_s
    begin
      I18n.locale = partner_account.get_country.default_locale
    rescue
      I18n.locale = 'en'
    end

    @owner_account = owner_account
    @owner_agreement = exchange_agreement.agreements.where(owner: owner_account.id).first
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_account.id).first

    @has_rejected_terms = @partner_agreement.has_rejections?()
    subject = t('automated_messages.exchange_agreement_created.subject',
                {:OWNER_LISTING_NUMBER => @owner_agreement.listing_number, :PARTNER_LISTING_NUMBER => @partner_agreement.listing_number})
    mail(:to => "#{partner_account.contact.name} <#{partner_account.contact.email}>", :subject => subject)

    I18n.locale = current_locale

  end

  ##
  # Sends out initial information about a exchange agreement
  def exchange_agreement_started(partner_account, owner_account, exchange_agreement)

    current_locale = I18n.locale.to_s
    begin
      I18n.locale = partner_account.get_country.default_locale
    rescue
      I18n.locale = 'en'
    end

    @owner_account = owner_account
    @owner_agreement = exchange_agreement.agreements.where(owner: owner_account.id).first
    @partner_agreement = exchange_agreement.agreements.where(owner: partner_account.id).first

    subject = t('automated_messages.exchange_agreement_created.subject',
                {:OWNER_LISTING_NUMBER => @owner_agreement.listing_number, :PARTNER_LISTING_NUMBER => @partner_agreement.listing_number})
    mail(:to => "#{partner_account.contact.name} <#{partner_account.contact.email}>", :subject => subject)

    I18n.locale = current_locale
  end

  def exchange_reference(to_account, from_listing_number)
    @listing_number = from_listing_number
    mail(:to => "#{to_account.contact.name} <#{to_account.contact.email}>", :subject => t('automated_messages.new_exchange_reference.subject'))
  end

  def green_light_reminder(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'green_light_reminder', :countries.in => [user.account.country_short]).first

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      #@placeholders[:LAST_LOGIN_IN_DAYS] = ((Time.now.utc - @user.account.accessed_at.utc).to_i / 3600 / 24)
      @placeholders[:LAST_LOGIN_IN_DAYS] = @message.days
      begin
        @placeholders[:LISTING_ID] = @user.account.listings.first.listing_number
      rescue Exception => e
        @placeholders[:LISTING_ID] = 'NO LISTING'
      end

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'green_light_reminder', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the first expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.green_light_reminder.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  def exchange_date_reminder(user)
    begin
      @user = user
      @account = @user.account

      return if @account.has_received_exchange_dates_email_at &&
                (@account.has_received_exchange_dates_email_at + 1.month) > DateTime.current

      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'exchange_dates_reminder', :countries.in => [user.account.country_short]).try(:first)

      return if @message.nil?

      @placeholders = {}
      @placeholders[:FAMILY_NAME] = @user.name

      begin
        @placeholders[:LISTING_ID] = @account.listings.first.listing_number
      rescue e
        @placeholders[:LISTING_ID] = 'NO LISTING'
      end

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.try(:name)
      @agent_placeholders[:MY_EMAIL] = @agents.first.try(:email)
      @agent_placeholders[:MY_PHONE] = @agents.first.try(:agent_profile).try(:telephone)
      @agent_placeholders[:MY_COUNTRY] = @agents.first.try(:agent_profile).try(:country)
      @agent_placeholders[:MY_URL] = @agents.first.try(:agent_profile).try(:website)
      @placeholders.merge!(@agent_placeholders)

    rescue e
      NotificationMailer.oddity("There seems to be something wrong with the first expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue e
      subject = t('automated_messages.exchange_date_reminder.subject')
    end

    @account.update_attribute(:has_received_exchange_dates_email_at, DateTime.now)

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  def reply_to_exchange_reminder(user, conversation)
    @user = user
    @account = @user.account

    @agents = User.get_agent_profiles_for_country(user.account.country_short)
    @message = AutomatedMessage.where(kind: 'reply_to_exchange_reminder', :countries.in => [user.account.country_short]).try(:first)

    if @message.nil?
      Rails.logger.error("No automated message for 'reply_to_exchange_request' with country code #{user.account.country_short}")
      return false
    end
    return false if @account.listings.empty?

    @placeholders = {}
    @placeholders[:FAMILY_NAME] = @user.name

    @placeholders[:LISTING_ID] = @account.listings.first.listing_number

    @agent_placeholders = {}
    @agent_placeholders[:MY_NAME] = @agents.first.try(:name)
    @agent_placeholders[:MY_EMAIL] = @agents.first.try(:email)
    @agent_placeholders[:MY_PHONE] = @agents.first.try(:agent_profile).try(:telephone)
    @agent_placeholders[:MY_COUNTRY] = @agents.first.try(:agent_profile).try(:country)
    @agent_placeholders[:MY_URL] = @agents.first.try(:agent_profile).try(:website)
    @placeholders.merge!(@agent_placeholders)

    subject = @message.subject

    if @message.nil?
      @message = AutomatedMessage.where(kind: 'reply_to_exchange_reminder', :countries.in => ['default']).first
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  def trial_expiration(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'trial_expiration', :countries.in => [user.account.country_short]).first
      @deactivation_date = @user.account.current_subscription.expires_at
      @expire_days = (@user.account.current_subscription.expires_at.utc.to_i - DateTime.now.utc.to_i) / 3600 / 24
      @expire_days = @expire_days + 1

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      @placeholders[:SUBSCRIPTION_LINK] = ActionController::Base.helpers.link_to(t('upgrade.link'), upgrade_subscriptions_url)
      @placeholders[:DEACTIVATION_DATE] = standard_date(@deactivation_date)
      @placeholders[:EXPIRE_DAYS] = @expire_days

      begin
        @placeholders[:LISTING_ID] = @user.account.listings.first.listing_number
      rescue Exception => e
        @placeholders[:LISTING_ID] = 'NO LISTING'
      end

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'trial_expiration', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the trial expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.trial_expiration.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  ##
  # Sent to trial accounts when they get messages or exchange requests
  def trial_message_notification(message, user, sent_by_account_id)
    @message = message
    @user = user
    @sender_account = Account.find(sent_by_account_id)
    current_locale = I18n.locale.to_s
    begin
      I18n.locale = user.account.get_country.default_locale
    rescue
      I18n.locale = 'en'
    end

    @agents = User.get_agent_profiles_for_country(user.account.country_short)
    if Rails.env.production? or Rails.env.staging? then
      email = mail(:to => "<#{user.email}>", :subject => t('notification.trial_subject'))
    else
      email = mail(:to => "<#{user.email}>", :subject => "TEST Someone at Intervac has sent you a message TEST")
    end
    I18n.locale = current_locale
    return email
  end

  ##
  # Sends out a thank you message on subscription renewal
  def membership_renewal(user)

    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'renewal_thank_you', :countries.in => [user.account.country_short]).first

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      begin
        @placeholders[:LISTING_ID] = @user.account.listings.first.listing_number
      rescue Exception => e
        @placeholders[:LISTING_ID] = 'NO LISTING'
      end

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'renewal_thank_you', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the first expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.membership_renewal.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  ##
  # Message for activating new members
  def membership_activation(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'new_member_activation', :countries.in => [user.account.country_short]).first

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'new_member_activation', :countries.in => ['default']).first
      end

    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the first expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.membership_activation.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  ##
  # Message for activating new members
  def membership_renewal_activation(user)

    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @message = AutomatedMessage.where(kind: 'membership_renewal_activation', :countries.in => [user.account.country_short]).first

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      begin
        @placeholders[:LISTING_ID] = @user.account.listings.first.listing_number
      rescue Exception => e
        @placeholders[:LISTING_ID] = 'NO LISTING'
      end

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'membership_renewal_activation', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the first expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.membership_renewal_activation.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  ##
  #
  def first_expiration_notification(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @expire_days = (@user.account.current_subscription.expires_at.utc.to_i - DateTime.now.utc.to_i) / 3600 / 24
      # Need to add one day because how we interpret an expire date today. Decision is to if it expires today we should show expires in 1 day.
      @expire_days = @expire_days + 1
      @deactivation_date = @user.account.current_subscription.expires_at
      @message = AutomatedMessage.where(kind: 'first_expiration_notification', :countries.in => [user.account.country_short]).first

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      @placeholders[:EXPIRE_DAYS] = @expire_days
      @placeholders[:DEACTIVATION_DATE] = standard_date(@deactivation_date)
      @placeholders[:LISTING_ID] = @user.account.listings.try(:first).try(:listing_number)


      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'first_expiration_notification', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the first expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.first_expiration_notification.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  def second_expiration_notification(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @expire_days = (@user.account.current_subscription.expires_at.utc.to_i - DateTime.now.utc.to_i) / 3600 / 24
      # Need to add one day because how we interpret an expire date today. Decision is to if it expires today we should show expires in 1 day.
      @expire_days = @expire_days + 1
      @deactivation_date = @user.account.current_subscription.expires_at
      @message = AutomatedMessage.where(kind: 'second_expiration_notification', :countries.in => [user.account.country_short]).first

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      @placeholders[:EXPIRE_DAYS] = @expire_days
      @placeholders[:DEACTIVATION_DATE] = standard_date(@deactivation_date)
      @placeholders[:LISTING_ID] = @user.account.listings.try(:first).try(:listing_number)

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'second_expiration_notification', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the second expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.second_expiration_notification.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  def third_expiration_notification(user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @deactivation_date = @user.account.current_subscription.expires_at
      @message = AutomatedMessage.where(kind: 'third_expiration_notification', :countries.in => [user.account.country_short]).first

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      @placeholders[:EXPIRE_DAYS] = @expire_days
      @placeholders[:DEACTIVATION_DATE] = standard_date(@deactivation_date)
      @placeholders[:LISTING_ID] = @user.account.listings.try(:first).try(:listing_number)

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      if @message.nil?
        @message = AutomatedMessage.where(kind: 'third_expiration_notification', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the third expiration for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.third_expiration_notification.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  ##
  # Special notifier for Kristina
  def french_payment_notification(user, order, price_plan)
    @user = user
    @order = order
    @price_plan = price_plan

    mail(:to => "<info@intervac.fr>", :subject => "New French Payment")
  end

  ##
  # Welcome mail for paying users
  def welcome_home(exchange_feedback, user)
    begin
      @user = user
      @agents = User.get_agent_profiles_for_country(user.account.country_short)
      @exchange_feedback = exchange_feedback

      @placeholders = {}
      @placeholders[:MEMBER_NAME] = @user.name
      @placeholders[:FAMILY_NAME] = @user.name
      @placeholders[:FAMILY_ID] = @user.account.account_number
      @placeholders[:COUNTRY] = @user.account.country_short
      @placeholders[:LOGIN] = @user.email
      @placeholders[:LISTING_ID] = @user.account.listings.try(:first).try(:listing_number)

      @agent_placeholders = {}
      @agent_placeholders[:MY_NAME] = @agents.first.name
      @agent_placeholders[:MY_EMAIL] = @agents.first.email
      @agent_placeholders[:MY_PHONE] = @agents.first.agent_profile.telephone
      @agent_placeholders[:MY_FAX] = @agents.first.agent_profile.fax
      @agent_placeholders[:MY_URL] = @agents.first.agent_profile.website

      @placeholders.merge!(@agent_placeholders)

      @message = AutomatedMessage.where(kind: 'welcome_home', :countries.in => [user.account.country_short]).first
      if @message.nil?
        @message = AutomatedMessage.where(kind: 'welcome_home', :countries.in => ['default']).first
      end
    rescue => e
      NotificationMailer.oddity("There seems to be something wrong with the welcome message for user #{@user.id} and message #{@message}. Error: #{e}").deliver
    end

    begin
      subject = @message.subject
    rescue Exception => e
      subject = t('automated_messages.welcome_home.subject')
    end

    mail_info = build_mail_info(@user, subject, @message, @agents)
    mail(mail_info)
  end

  def deploy_notification(to)
    now = Time.now.utc
    msg = "New updates and bug fixes has been uploaded to the staging server on #{standard_date(now)} at #{now.localtime.strftime("%H:%M:%S")}."

    mail(:to => to,
         :subject => "Deployed new version to staging") do |format|
      format.text { render :text => msg}
      format.html { render :text => "<p>#{msg}</p>"}
    end
  end

  def payment_notification(params, state, exception = nil)
    msg = "New French payment notification \n #{params}"

    if not exception.nil?
      msg += "\n #{exception}"
    end

    msg += "\n #{state}"

    mail(:to => "<webmaster@intervac.com>",
         :subject => "New Payment Notification") do |format|
      format.text { render :text => msg}
      format.html { render :text => "<p>#{msg}</p>"}
    end
  end

  def undeliverable(to, subject)
    msg = t('automated_messages.email_could_not_be_delivered', {:SUBJECT => subject})

    mail(:to => to,
         :subject => t('automated_messages.email_not_delivered')) do |format|
      format.text { render :text => msg}
      format.html { render :text => "<p>#{msg}</p>"}
    end
  end

  def oddity(odd_message)
    msg = odd_message

    mail(:to => "<webmaster@intervac.com>",
         :subject => "Something odd did just happen") do |format|
      format.text { render :text => msg}
      format.html { render :text => "<p>#{msg}</p>"}
    end
  end

  def sorry(user)
    @user = user

    subject = "Regarding active listing reminder e-mails"

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "<#{user.email}>", :subject => subject)
    else
      mail(:to => "<#{user.email}>", :subject => subject)
    end
  end

  def sorry_fr(user)
    @user = user

    subject = "Concernant message automatique"

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "<#{user.email}>", :subject => subject)
    else
      mail(:to => "<#{user.email}>", :subject => subject)
    end
  end

  def sorry_de(user)
    @user = user

    subject = "Betrefft Erinnerungsemail"

    if Rails.env.production? or Rails.env.staging? then
      mail(:to => "<#{user.email}>", :subject => subject)
    else
      mail(:to => "<#{user.email}>", :subject => subject)
    end
  end

  private

  ##
  # Builds the mail sender headers like receivers and subject for automated messages to easier handle bcc copy to agents.
  def build_mail_info(user, subject, message, agents)

    if Rails.env.development?
      subject = "TEST #{subject} TEST"
    end

    to_address = [{name: user.name, email: user.email}]

    if not user.secondary_email.blank?
      to_address.push({name: user.name, email: user.secondary_email})
    end

    to_address = to_address.collect {|u| "#{u[:name]} <#{u[:email]}>"}.join ', '

    mail_info = {
      to: to_address,
      subject: subject
    }

    begin
      if message.send_copy_to_agent
        bcc_agents = ""
        agents.each do |agent|
          bcc_agents << "<#{agent.email}>,"
        end
        mail_info[:bcc] = bcc_agents
      end
    rescue
      NotificationMailer.oddity("There seems to be something wrong with the message: #{message}").deliver
    end

    mail_info
  end
end
