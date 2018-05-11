module Mobile::FavoritesHelper

  # Puts out the correct link if a listing is added as a favorite or not.
  def act_as_favorite_mobile(listing)
    
    if listing.account == current_user.account
      return ''
    end
    
    listing_id = listing.id
    
    favorites = []
    
    current_user.account.favorites.each do |favorite|
      favorites.push(favorite.listing_id)
    end    
    # Remove links generated if the listing already is a favorite on the account
    if favorites.include?(listing_id.to_s)
      return link_to(t('mobile.listings.remove_favorite'), mobile_remove_as_favorite_path(listing_id), remote: true, id: 'btn-favorite', class: 'button button-yellow-green')
    end
    
    # Create links generated if the listing isn't a favorite on the account    
    return link_to(t('mobile.listings.add_favorite'), mobile_add_as_favorite_path(listing_id), remote: true, id: 'btn-favorite', class: 'button button-yellow-green')
  end

end
