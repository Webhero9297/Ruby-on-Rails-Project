class ConversationMailer < ActionMailer::Base
  default from: "Intervac conversation <#{Rails.application.config.conversation_email}>"
  add_template_helper(ApplicationHelper)
  
  def contact(receiver_account, message)
    @receiver_account = receiver_account
    @listing_owner = @receiver_account.get_owner
    
    @message = message
    @sender_account = Account.find(message.sent_by_account)
    
    @locale = @receiver_account.get_country.default_locale

    receivers = []

    @receiver_account.users.each do |user|
      receiver = {name: user.name, email:user.email}
      receivers.push(receiver)
      next if user.secondary_email.blank?
      receiver = {name: user.name, email:user.secondary_email}
      receivers.push(receiver)
    end

    receivers = receivers.collect {|u| "#{u[:name]} <#{u[:email]}>"}.join ', '

    subject = "New Intervac message from #{message.sent_by_user}"
    if @message.kind == 'exchange_request'
      subject = "New Intervac Exchange Request from #{message.sent_by_user}"
    end

    mail(:to => receivers, :subject => subject)
  end


  def contact_agent(receiver_account, message)
    @receiver_account = receiver_account
    @contact = @receiver_account.users.first
    
    @message = message
    @sender_account = Account.find(message.sent_by_account)
    
    @locale = @receiver_account.get_country.default_locale

    receivers = []

    @receiver_account.users.each do |user|
      receiver = {name: user.name, email:user.email}
      receivers.push(receiver)
      next if user.secondary_email.blank?
      receiver = {name: user.name, email:user.secondary_email}
      receivers.push(receiver)
    end

    receivers = receivers.collect {|u| "#{u[:name]} <#{u[:email]}>"}.join ', '
    
    if @sender_account.has_listing?
      listing_number = @sender_account.listings.first.listing_number
    end

    @agent_extras = "#{@message.sent_by_user} (#{listing_number}) - #{@sender_account.contact.postal_code} #{@sender_account.contact.postal_town}, #{I18n.t(@sender_account.get_country.msgid)} - Tel: #{@sender_account.contact.telephone} - Email: #{@sender_account.contact.email}"

    subject = message.conversation.subject
    
    if @message.kind == 'exchange_request'
      subject = "New Intervac Exchange Request from #{message.sent_by_user}"
    end

    mail(:to => receivers, :subject => subject)
  end
  
end