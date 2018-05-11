# encoding: utf-8
class ApplicationController < ActionController::Base
  protect_from_forgery
  
  include GeoAndLocaleSettings
  include SslHelpers

  before_filter { |c| Authorization.current_user = c.current_user }
  before_filter :geo_and_user_check
  before_filter :check_agent_locale_access
  before_filter :close_hammer
  before_filter :update_accessed_at
  before_filter :cookie_information_alert

  # Me wonder why we have these here also. I think is because we use them somewhere where the helpers do not reach...
  # Translation helper that simplifies variable substitution for Gettext
  def _(text)
    text.html_safe
  end

  def close_hammer
    HAMMER.close
  end

  def update_accessed_at
    if current_user and user_signed_in? and session[:management_user_id].nil?
      now = Time.now.utc
      next_now = now - 1.hour
      if session[:accessed_at] and session[:accessed_at] > next_now
        return
      end
      current_user.account.set(:accessed_at, now)
      session[:accessed_at] = now
    end
  end

  
  def check_agent_locale_access
    #@can_translate = false
    session[:can_translate] = true

    if current_user
      if current_user.is_admin #Admin can do everything :)
        #@can_translate = true
        session[:can_translate] = true
        return
      end
      if current_user.is_agent
        cookie_jar = CookieJar.get_cookie(cookies[:intervac_user])
        if cookie_jar and current_user.agent_profile.locales.include?(cookie_jar.locale)
         # @can_translate = true
         session[:can_translate] = true
        end
      end
    end
  end
  
  # Overrides the normal t method in order to make it html_safe
  def t(text, args = {})
    return if text.nil?

    I18n.t(text, args).html_safe
  end
  
  protected
  
  ##
  # Is run after the user has signed in via devise.
  def after_sign_in_path_for(resource)
    ##

    #Updates last login at on account
    resource.account.set(:last_login_at, Time.now.utc)

    # Set the time zone session for the user instead of always fetching it from the account
    set_session_time_zone(resource.account.time_zone)

    # Checks if the account has been activated or not.
    # If the account hasn't been activated the user will be redirected to free or paid account confirmation pages.
    if resource.account.activated_at.nil?
      
      price_plan_id = resource.account.orders.first.price_plan_id
      price_plan = Country.get_price_plan_by_country_and_id(resource.account.country_short, price_plan_id)

      if price_plan.kind == 'free'
        return free_plan_confirmation_url
      end
      
      return paid_plan_confirmation_url
    end
    
    ##
    # Checks if the account has expired. If the account has expired it will have restricted access inside the system.
    if resource.account.current_subscription.expires_at < Date.today.to_time.utc then
      resource.account.restrict_access_for_users
    end

    # If mobile client redirect to mobile dashboard
    if session[:mobile_login_url]
      url = session[:mobile_login_url]
      session[:mobile_login_url] = nil
      return url
    end

    if resource.roles.include?('member') and resource.roles.include?('agent') and resource.roles.include?('admin')
      return management_agent_dashboard_path
    end

    if resource.roles.include?('member') and resource.roles.include?('admin')
      return member_dashboard_url
    end
    
    if resource.roles.include?('agent')
      return management_agent_dashboard_path
    end
    
    if resource.roles.include?('admin') and not resource.roles.include?('agent')
      return management_admin_dashboard_path
    end
    
    # Should we redirect after login?
    if session[:after_login_url]
      url = session[:after_login_url]
      session[:after_login_url] = nil
      return url
    end

    member_dashboard_url
  end
  
  ##
  # Is run after the user has signed out.
  def after_sign_out_path_for(resource_or_scope)
    logged_out_url
  end
  
  def after_inactive_sign_up_path_for(resource)
    signed_up_url
  end
  
  ##
  # Used by authoritative declaration when a user doesn't have access to the specific route.
  def permission_denied
    if user_signed_in?
      flash[:notice] = t('alert.not_allowed_to_access_page')
      redirect_to after_sign_in_path_for(current_user)#Redirect to correct dashboard instead of no_access_url
      return
    end

    if session[:mobile_login_url]
      redirect_to(mobile_login_url)
      return
    end

    # If not logged in redirect to login with a return url in mind
    session[:after_login_url] = request.url
    redirect_to login_url
  end
  
  ##
  # Used to set the right dashboard for users with access to multiple dashboards.
  def set_dashboard_scope(dashboard)
    session[:dashboard] = dashboard
  end

  ##
  # Checks if current session is admin
  def admin_session?
    if session[:dashboard] == 'admin'
      return true
    end

    false
  end

  ##
  # Checks if current session is agent
  def agent_session?
    if session[:dashboard] == 'agent'
      return true
    end

    false
  end


  ##
  # Checks if current session is member dashboard
  def member_session?
    if session[:dashboard] == 'member'
      return true
    end
    false
  end

  def set_as_mobile
    session[:is_mobile] = true
  end

  def is_mobile
    return true if session[:is_mobile]

    false
  end

  ##
  # Checks the session to see if the user is translating
  def user_can_translate?
    return true if session[:can_translate]

    false
  end

  ##
  # Checks the session to see if the user is translating
  def is_translating?
    return true if session[:is_translating]

    false
  end

  ##
  # Toggles the translation session
  def toggle_translating_session
    return session[:is_translating] = false if session[:is_translating]

    session[:is_translating] = true
  end

  def check_subscription
    if current_user && current_user.account.activated_at.nil?

      price_plan_id = current_user.account.orders.first.price_plan_id
      price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, price_plan_id)

      if price_plan.kind == 'free'
        redirect_to free_plan_confirmation_url
      end

      redirect_to paid_plan_confirmation_url
    end
  end
  ##
  # Wrap form fields errors using a span instead of the default div
  ActionView::Base.field_error_proc = Proc.new do |html_tag, instance_tag|
    "<span class='field-error'>#{html_tag}</span>".html_safe
  end

  ##
  # Sets the session time zone, if the account does not have a time zone the time zone is set to UTC
  def set_session_time_zone(time_zone)
    if time_zone.blank?
      session[:time_zone] = "UTC"
    else
      session[:time_zone] = time_zone
    end
  end

  ##
  # Returns the time zone set in the session
  def get_session_time_zone
    session[:time_zone]
  end

  def cookie_information_alert
    if cookies[:cookie_bar].nil?
      cookies.permanent[:cookie_bar] = {:value => 'yes', :domain => :all}
    end
  end
end
