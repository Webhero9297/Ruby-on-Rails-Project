# encoding: UTF-8
class Accounts::FavoritesController < ApplicationController
  filter_access_to :all
  layout "dashboard"

  def index
    @account = Account.find(params[:account_id])
    @favorite_listings = @account.get_favorites()
    @favorite_notes = @account.get_favorite_notes()
  end
end
