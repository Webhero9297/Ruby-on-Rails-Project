# encoding: UTF-8
class Agent::ExchangeAgreementsController < ApplicationController
  filter_access_to :all
  layout 'management'

  def index
    agent_country_short_codes = current_user.agent_profile.get_assigned_countries_short_codes
    @exchange_agreements = ExchangeAgreement.agent_members(agent_country_short_codes).limit(30).order_by([[:created_at, :desc]])

    respond_to do |format|
      format.html
    end
  end

  def show
    @exchange_agreement = ExchangeAgreement.find(params[:id])

    @member_agreement  = @exchange_agreement.agreements[0]
    @partner_agreement = @exchange_agreement.agreements[1]

    @member  = Account.find(@member_agreement.owner)
    @partner = Account.find(@partner_agreement.owner)

    respond_to do |format|
      format.html
    end
  end

  def search
    @query = params['query'].strip
    @exchange_agreements = ExchangeAgreement.where(:'agreements.listing_number' => @query).order_by([[:created_at, :desc]])
    @count = @exchange_agreements.to_a.length

    respond_to do |format|
      format.html
      format.js
    end
  end

  def destroy
    exchange_agreement = ExchangeAgreement.find(params[:id])
    exchange_agreement.destroy

    respond_to do |format|
      format.html { redirect_to( agent_exchange_agreements_url, notice: 'Exchange agreement deleted.' ) }
    end
  end
end
