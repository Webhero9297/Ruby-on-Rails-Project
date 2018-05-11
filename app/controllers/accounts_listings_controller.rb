# encoding: UTF-8
class AccountsListingsController < ApplicationController

  layout 'dashboard'

  def build
    
    AccountsListing.build_collection

    render(text: 'Yeah, that worked well')
  end

end
