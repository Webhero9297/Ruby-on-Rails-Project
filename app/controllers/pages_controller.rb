# encoding: utf-8
class PagesController < ApplicationController
  before_filter { |c| c.set_dashboard_scope 'site' }

  def index

    vip_countries = Country.get_shorts_as_array('vip')
    vip_countries = vip_countries.sample(60)
    @listings = Listing.searchable.where(:country_code.in => vip_countries).order_by(:updated_at, :desc).limit(4)

    oc_countries = Country.get_shorts_as_array('oc')
    oc_countries = oc_countries.sample(60)
    @oc_listings = Listing.searchable.where(:country_code.in => oc_countries).order_by(:updated_at, :desc).limit(4)

    country_short = CookieJar.country_short(cookies[:intervac_user])
    @paid_plan = Country.get_default_price_plan(country_short)

  end

  def landing
    country_short = "GB"
    @price_plan = Country.get_trial_plan_for_country(country_short)
    @visitor_country = Country.get_by_short_code(country_short)
    @national_representatives = User.get_agent_profiles_for_country(country_short)

    render(:layout => 'landing_pages_layout')
  end

  def video_presentation
    respond_to do |format|
      format.html { render :layout => false }
      format.js { render :layout => false }
    end
  end

  def what_is_home_exchange
    render(:template => 'pages/exchange/what_is_home_exchange')
  end

  def benefits_of_home_exchange
    render(:template => 'pages/exchange/benefits_of_home_exchange')
  end

  def home_exchange_with_intervac
    render(:template => 'pages/exchange/home_exchange_with_intervac')
  end

  def what_to_think_about
    render(:template => 'pages/exchange/what_to_think_about')
  end

  def home_exchange_checklist
    render(:template => 'pages/exchange/home_exchange_checklist')
  end

  def exchange_tips
    render(:template => 'pages/exchange/exchange_tips')
  end

  def facts_about_intervac
    render(:template => 'pages/intervac/facts_about_intervac')
  end

  def membership_with_intervac
    render(:template => 'pages/intervac/membership_with_intervac')
  end

  def secure_exchanges
    render(:template => 'pages/intervac/secure_exchanges')
  end

  def local_representatives
    render(:template => 'pages/intervac/local_representatives')
  end

  def words_from_our_members
    render(:template => 'pages/intervac/words_from_our_members')
  end

  def our_guarantee
    render(:template => 'pages/intervac/guarantee')
  end

  def press_coverage
    render(:template => 'pages/intervac/press_coverage')
  end

  def channel
    render(:template => 'pages/channel', layout: false)
  end

  def privacy_policy
    render(:template => 'pages/legal/privacy_policy')
  end

  def terms_of_use
    render(:template => 'pages/legal/terms_of_use')
  end

  def cookie_information
    render(:template => 'pages/legal/cookie_information')
  end

  def logged_out
    render(:template => 'pages/logged_out')
  end

  def signed_up
    render(:template => 'pages/signed_up')
  end

  def facebook_login_information
    render(:template => 'pages/facebook_login_information')
  end

  def facebook_competition
    render(:template => 'pages/facebook_competition')
  end

  def no_access; end
end
