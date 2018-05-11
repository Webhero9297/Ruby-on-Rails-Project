# encoding: UTF-8
class Accounts::ContactRestrictionsController < ApplicationController
  
  filter_access_to :all
  layout 'dashboard'

  def edit
    
    @account = Account.has_permission(current_user).find(params[:account_id])
    @country = Country.get_by_short(@account.country_short)
    
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    
    begin
      @account = Account.has_permission(current_user).find(params[:account_id])
    rescue Exception => e
      render( template: '/pages/no_access.html' )
      return
    end

    @country = Country.get_by_short(@account.country_short)

    contact_restriction = ContactRestriction.new(contact_restrictions_params)
    respond_to do |format|
      if @account.contact_restrictions = contact_restriction
        format.html { redirect_to(edit_account_contact_restrictions_url, notice: t('alert.contact_restrictions_updated')) }
        format.js
      else
        format.html { render action: "edit" }
        format.js { render action: "edit" }
      end
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
      if @account.contact_restrictions.update_attributes(contact_restrictions_params)
        format.html { redirect_to(edit_account_contact_restrictions_url, notice: t('alert.contact_restrictions_updated')) }
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

  def contact_restrictions_params
    params.require(:contact_restrictions).permit(:added_as_favorite)
  end
end
