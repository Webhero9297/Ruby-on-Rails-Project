module FavoritesHelper
  
  def note_for_favorite(listing_id)
    
    note = current_user.account.where("favorites.listing_id" => listing_id)
    return note
  end
  
end
