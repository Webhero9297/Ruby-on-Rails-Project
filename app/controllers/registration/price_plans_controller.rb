# encoding: UTF-8
class Registration::PricePlansController < ApplicationController
  force_ssl if: :ssl_configured?
  filter_access_to :index, :options, :promotion_code

  def index
    @countries = Country.sorted_by_language
    country_short = CookieJar.country_short(cookies[:intervac_user])
    @paid_plan = Country.get_default_price_plan(country_short)
    @trial_plan = Country.get_trial_plan_for_country(country_short)
    @price_plans = Country.where(short: country_short.upcase).first.price_plans.where(kind: 'paid', active: true)
    
    begin
      country_short = CookieJar.country_short(cookies[:intervac_user]).upcase
      @countries = Country.sorted_by_language()
      @visitor_country = Country.get_by_short_code(country_short)
    rescue Exception => e

    end

    respond_to do |format|
      format.html
    end
  end


  def options
    country_short = CookieJar.country_short(cookies[:intervac_user])
    @price_plans = Country.where(short: country_short.upcase).first.price_plans.where(kind: 'paid', active: true)

    respond_to do |format|
      format.html
    end
  end


  def promotion_code
    code = params[:promotion_code].upcase

    country_short = CookieJar.country_short(cookies[:intervac_user])
    @country = Country.where(short: country_short.upcase).first

    @price_plan = @country.price_plans.find(params[:price_plan_id])

    @promotion_code = @price_plan.promotion_codes.where(code: code).first.presence

    if @promotion_code
      @promotion_code = false if !@promotion_code.redeemable?
    end

    respond_to do |format|
      format.js
    end
  end


  def country_of_residence

    country_short = params[:country_short]

    respond_to do |format|
      format.html { redirect_to(change_country_path(country_short)) }
      format.js
    end
  end

end
