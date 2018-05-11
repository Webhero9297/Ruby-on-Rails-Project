module Listing::ExchangeDatesHelper
  
  def exchange_input_date(msg_date)
    if msg_date.nil?
      return ''
    end
    msg_date.strftime("%Y-%m-%d")
  end
  
  
  def exchange_date(msg_date)
    if msg_date.nil?
      return ""
    end
    msg_date.strftime("%B %d, %Y")
  end
  
  
  def length_of_stay(listing)
    
    if not listing.exchange_dates.empty?
      return "#{listing.exchange_dates[0].length_of_stay} #{listing.exchange_dates[0].periodicity}"
    end
    
    return "Unspecified"
  end
  
end
