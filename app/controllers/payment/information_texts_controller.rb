# encoding: UTF-8
class Payment::InformationTextsController < ApplicationController

  #filter_access_to :all
  layout "management"

  def show
    
    country = current_user.agent_profile.get_assigned_countries.first

    if country.offline_payment_text.empty? or country.offline_payment_text.nil?
      @info_text = ''
    else
      @info_text = current_user.agent_profile.get_assigned_countries.first.offline_payment_text
    end

    respond_to do |format|
      format.html
    end
  end


  def update

    current_user.agent_profile.get_assigned_countries.each do |country|
      country.set_offline_payment_text(params[:information_text])
    end

    respond_to do |format|
      format.html { redirect_to(information_text_path, notice: 'The payment information text has been updated') }
    end
  end

end
