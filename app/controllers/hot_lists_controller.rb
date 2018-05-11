# encoding: UTF-8
class HotListsController < ApplicationController
  filter_access_to :all
  layout 'application'
  
  def show
    
    @listings = Listing.searchable.in_hot_list.order_by([:updated_at, :desc]).page(params[:page]).per(12)
    
    respond_to do |format|
      format.html
    end
    
  end
  
end
