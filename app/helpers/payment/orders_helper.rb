module Payment::OrdersHelper
  
  # Checks if the user should use the French custom payment gateway.
  def french_payment?(user)

    if Rails.application.config.french_sites.include?(current_user.account.country_short) then
      return true
    end
    
    return false
  end

  # Checks if the user should pay via Sage Pay.
  def sage_pay?(user)

    if Rails.application.config.sage_pay_sites.include?(current_user.account.country_short) then
      return true
    end
    
    return false
  end


end
