module HotListsHelper
  
  def has_listings_in_hot_list
    
    current_user.account.listings.each do |listing|
      if listing.is_in_hot_list
        return true
      end
    end
    
    return false
  end
  
end
