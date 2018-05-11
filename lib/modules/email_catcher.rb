class EmailCatcher
  def self.delivering_email(message)

    filtered_mailers = %w[
      NotificationMailer
      ConversationMailer
    ]

    if filtered_mailers.include?(message.delivery_handler.to_s)
      message.subject = "[filter] To:#{message.to} - #{message.subject}"
      message.to = '<webmaster@intervac.com>'
    end

    message
  end
end
