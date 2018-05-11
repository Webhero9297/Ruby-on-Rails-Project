# encoding: UTF-8
require "action_mailer"
require "active_support"
require 'openssl'
require 'restclient'

module ModondoMailgun
  class MailgunError < RuntimeError
    attr_reader :message

    def initialize message
      @message = message
    end
  end

  class DeliveryError < StandardError
  end

  class DeliveryMethod
    attr_accessor :settings

    def initialize(settings)
      self.settings = settings
    end

    def api_host
      self.settings[:api_host]
    end

    def api_key
      self.settings[:api_key]
    end

    def deliver!(mail)
      # It was using multimap to create needed for Mailgun http API. This were
      # is easer than building the e-mail with a mime lib and the implied way
      # to do it by Mailgun. But we're changing to a simple `Hash` in order to
      # remove the old and buggy multimap dependency.
      data = {}
      data[:from] = mail.from
      data[:to] = mail.destinations.join(',')
      data[:subject] = mail.subject

      # Checks if the e-mail is a multipart message with both html and text
      if mail.multipart?
        mail.parts.each do |part|
          if part.content_type.include?('plain')
            data[:text] = part.body
          end

          if part.content_type.include?('html')
            data[:html] = part.body
          end
        end
      end

      # If the mail is not a multipart message the correct mail container is set for the message
      if mail.mime_type == 'text/plain'
        data[:text].is_a?(Array) ? data[:text] << mail.body : data[:text] = mail.body
      end

      if mail.mime_type == 'text/html'
        data[:html].is_a?(Array) ? data[:html] << mail.body : data[:html] = mail.body
      end

      # Makes the api request to Mailgun who sends the e-mail
      begin
        response = RestClient.post("https://api:#{self.api_key}@#{self.api_host}", data)
        result = ActiveSupport::JSON.decode(response)
        mail.message_id = result['id']
      rescue => e
        Rails.logger.error "Error when trying to send an email via mailgun API: #{e.inspect}"
      end
    end
  end

  class Verify
    def self.verify_message(token, timestamp, signature, api_key)
      signature == OpenSSL::HMAC.hexdigest(
        OpenSSL::Digest::SHA256.new, api_key, [timestamp, token].join
      )
    end
  end
end

ActionMailer::Base.add_delivery_method :mailgun, ModondoMailgun::DeliveryMethod
