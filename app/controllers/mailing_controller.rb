# encoding: UTF-8
class MailingController < ApplicationController
  skip_before_filter :geo_and_user_check

  def receive_message
    sender      = params['sender']
    subject     = params['subject']
    no_quotes   = params['stripped-text']
    message_id  = params['Message-Id']
    _from       = params['from']
    _recipient  = params['recipient']
    _body_plain = params['body-plain']

    verified = ModondoMailgun::Verify.verify_message(
      params['token'],
      params['timestamp'],
      params['signature'],
      Rails.application.config.verify_message_key
    )

    if not verified
      logger.warn("MESSAGE NOT VERIFIED")
      render nothing: true
      return
    end

    begin
      # Check that message id exists
      reply_to_id = params['In-Reply-To']
      if reply_to_id.blank?
        NotificationMailer.undeliverable(sender, "#{subject}. (reason: reply_to missing)").deliver
      else
        conversation  = Conversation.get_by_mailgun_id(reply_to_id)
        part_accounts = Account.find(conversation.participants)

        non_eligible  = part_accounts.select do |account|
          account.terminated || account.is_expired?
        end

        if !privileged?(sender) && non_eligible.any?
          NotificationMailer.undeliverable(sender, "#{subject}. (reason: non_eligible)").deliver
        else
          status = Conversation.get_status_object(reply_to_id)
          user = Account.find(status.account_id).users.first
          message = conversation.messages.where(message_id: message_id).first
          if message.nil?
            message = conversation.reply(no_quotes, user)
            message.set(:message_id, message_id)
          end
        end
      end
    rescue => e
      logger.warn("Message could not be recieved. Probably missing In-Reply-To. Response: #{e.inspect}")
    ensure
      # Mailgun wants to see 2xx, otherwise it will make another attempt in 5 minutes
      render nothing: true
    end
  end

  def receive_status
    event = params['event']

    # TODO set receive_status for other mails than conversations.
    # TODO Handle errors properly for responding mails
    #if params['from'] == 'server@intervac-staging.mailgun.org' then
    #  EventLog.create!(raw_data: params)
    #  render :status => 200
    #  return
    #end

    if event == 'delivered'
      message_id = params['Message-Id']
      status = Conversation.get_status_object(message_id)
      if status
        status.set_delivered
      end
      render nothing: true
      return
    end

    if event == 'dropped'
      message_id = params['Message-Id']
      status = Conversation.get_status_object(message_id)
      if status
        status.set_failed
      end
      render nothing: true
      return
    end

    render nothing: true
    return
  end

  private

  def privileged? sender
    email = sender.scan(/\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,4}\b/i).first
    user  = User.find_by_email(email)
    user && (user.is_agent || user.is_admin)
  end
end
