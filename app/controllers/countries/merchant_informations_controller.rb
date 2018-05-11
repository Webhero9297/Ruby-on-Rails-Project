# encoding: UTF-8
class Countries::MerchantInformationsController < ApplicationController
  #filter_access_to :all
  layout "dashboard"
  
  def edit
    
    @country = Country.find(params[:country_id])
    @merchant_information = @country.merchant_information
    if @merchant_information.nil?
      @merchant_information = @country.build_merchant_information
    end
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def create
    
    @country = Country.find(params[:country_id])
    @merchant_information = @country.build_merchant_information(merchant_information_params)
    
    respond_to do |format|
      if @merchant_information.valid?
        @merchant_information.save
        format.html {redirect_to(country_path(@country))}
        format.js
      else
        format.html {render(action: 'edit')}
        format.js {render(action: 'edit')}
      end
    end
  end
  
  
  def update
    
    @country = Country.find(params[:country_id])
    @merchant_information = @country.merchant_information
    
    respond_to do |format|
      if @country.merchant_information.update_attributes(merchant_information_params)
        format.html {redirect_to(country_path(@country))}
        format.js
      else
        format.html {render(action: 'edit')}
        format.js {render(action: 'edit')}
      end
    end
  end

private
  
  def merchant_information_params
    params.require(:merchant_information).permit(:name, :address, :postal_code, :postal_town, :country_name, :phone, :fax, :email, :organisation_number)
  end

end
