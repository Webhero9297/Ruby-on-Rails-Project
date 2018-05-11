# encoding: UTF-8
class Accounts::ContactsController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'

  def show
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @country = Country.get_by_short(@account.country_short)
    
    respond_to do |format|
      format.html
    end
  end
  

  def edit
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @country = Country.get_by_short(@account.country_short)
    
    respond_to do |format|
      format.html
      format.js
    end
  end
  
  
  def update
    
    begin
      @account = Account.has_permission(current_user).find(params[:account_id])
    rescue Exception => e
      render( template: '/pages/no_access.html' )
      return
    end
    
    @country = Country.get_by_short(@account.country_short)
    
    respond_to do |format|
      if @account.contact.update_attributes(contact_params)
        format.html { redirect_to(edit_account_contacts_url, notice: t('alert.contact_information_updated')) }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render action: "edit" }
      end
    end
  end


  def cancel
    @account = Account.has_permission(current_user).find(params[:account_id])
    @country = Country.get_by_short(@account.country_short)
    
    respond_to do |format|
      format.html
      format.js
    end
  end


private

  def contact_params
    params.require(:contact).permit(:name, :birthdate, :address, :postal_town, :postal_code, :county,:telephone, :mobile, :fax, :email, :skype, :website, :contact_page)
  end
end
