module Payment::PricePlansHelper
  
  def has_more_than_one_paid_price_plan(price_plans)
    
    nr_of_price_plans = 0
    
    price_plans.each do |price_plan|
      if price_plan.kind == 'paid' then
        nr_of_price_plans = nr_of_price_plans + 1
      end
    end
    
    if nr_of_price_plans > 1 then
      return true
    end
    
    return false
  end
  
  
  def has_more_than_one_free_price_plan(price_plans)
    
    nr_of_price_plans = 0
    
    price_plans.each do |price_plan|
      if price_plan.kind == 'free' then
        nr_of_price_plans = nr_of_price_plans + 1
      end
    end
    
    if nr_of_price_plans > 1 then
      return true
    end
    
    return false
  end
  
  
  def has_more_than_one_active(price_plans, kind)
    
    nr_of_active_price_plans = 0
    
    price_plans.each do |price_plan|
      if price_plan.kind == kind and price_plan.active == true then
        nr_of_active_price_plans = nr_of_active_price_plans + 1
      end
    end
    
    if nr_of_active_price_plans > 1 then
      return true
    end
    
    return false
  end
  
  
  def float_price(price)
    begin
      price = sprintf( "%0.02f", price) 
    rescue
      price = price.to_i
    end
    return price
  end

  def renew_or_base_price(user, price_plan)
    if user.account.is_expired?
      return price_plan.base_price
    end
    return price_plan.renewal_price
  end
  
end
