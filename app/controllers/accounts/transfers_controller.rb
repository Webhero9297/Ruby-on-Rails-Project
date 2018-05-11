# encoding: UTF-8
class Accounts::TransfersController < ApplicationController
  filter_access_to :all
  layout 'management'
  

  def transfer_account
    
    @account = Account.find(params[:account_id])
    @countries = Country.sorted_by_language
    
    @account.transfer_to_country(params[:agent][:country])
    
    respond_to do |format|
      format.html {redirect_to(account_path, notice: t('alert.account_has_been_transferred'))}
    end
  end
  
  
end
