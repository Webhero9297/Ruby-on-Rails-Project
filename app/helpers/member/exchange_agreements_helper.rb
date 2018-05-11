module Member::ExchangeAgreementsHelper
  def show_status(exchange_agreement, account_id)
    if exchange_agreement.status == 'request_sent'
      if exchange_agreement.accepted_by.include?(account_id)
        return 'Exchange request sent'
      else
        return 'Exchange request received'
      end
    end

    if exchange_agreement.status == 'request_accepted'
      return 'Negotiating terms'
    end

    if exchange_agreement.status == 'started'
      return 'Started'
    end

    
    if exchange_agreement.status == 'request_rejected'
      if exchange_agreement.accepted_by.include?(account_id)
        return 'Exchange request was rejected'
      else
        return 'You rejected the exchange request'
      end
    end
  end
  
  def partner(exchange_agreement)
    Account.find exchange_agreement.get_partner_account_id(current_user.account.id)
  end
  
  def sign_button(exchange_agreement)
    if exchange_agreement.can_be_signed?
      return link_to('Sign the agreement', '#', :class => 'btn')
    end
    return "Need to accept each others terms in order to sign the agreement."
  end
  
  def check_done(check)
    if check
      return "step-done"
   end
  end

end
