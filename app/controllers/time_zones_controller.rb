# encoding: UTF-8
class TimeZonesController < ApplicationController
  filter_access_to :all
  layout 'dashboard'

  def show
    @account = Account.has_permission(current_user).find(params[:account_id])
    respond_to do |format|
      format.html
    end
  end


  def update
    @account = Account.find(params[:account_id])
    @account.set_time_zone(params[:account][:time_zone])
    set_session_time_zone(params[:account][:time_zone])

    flash[:notice] = t('time_zone.zone_set_successfully')
    respond_to do |format|
      format.html {redirect_to(listing_statistics_path)}
      format.js
    end
  end
end
