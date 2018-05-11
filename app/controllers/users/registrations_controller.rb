# encoding: utf-8
class Users::RegistrationsController < Devise::RegistrationsController
  include SslHelpers

  force_ssl if: :ssl_configured?

  def new
    _resource = build_resource({})
    session[:price_plans] = true

    if params[:account]
      country_short = params[:account][:country_short]
    else
      country_short = CookieJar.country_short(cookies[:intervac_user]).upcase
    end

    @countries = Country.sorted_by_language
    @visitor_country = Country.get_by_short_code(country_short)
    @national_representatives = User.get_agent_profiles_for_country(country_short)
    @price_plan = Country.get_price_plan_by_country_and_id(country_short, params[:id])

    if @price_plan.nil?
      @price_plan = Country.get_last_active_plan(country_short)
    end

    @promotion_code = nil

    if params[:promotion_code]
      @promotion_code = @price_plan.promotion_codes.find(params[:promotion_code])
    end

    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    session[:price_plans] = nil
    country_short = params[:account][:country_short]
    price_plan_id = params[:account][:price_plan]

    # Sets the promotion code ID to nil if the new sign up have not
    # used a promotion code. If promotion code is used the
    # promotion_code_id is set and used to fetch the promotion code
    # document.
    promotion_code_id = nil
    if params[:account][:promotion_code].present?
      promotion_code_id = params[:account][:promotion_code]
    end

    # The price plan the user is signing up for
    price_plan = Country.get_price_plan_by_country_and_id(country_short.upcase, price_plan_id)

    # If a promotion code has been used the promotion code document is fetched. Otherwise the promotion code document is nil.
    promotion_code = nil
    if promotion_code_id.present?
      promotion_code = price_plan.promotion_codes.find(promotion_code_id)
    end

    build_resource
    account = Account.build_new_account(params)

    # Save the user and account and merges everything together
    if resource.save and account.save!
      account.update_attribute(:account_owner, resource.id)
      resource.set(:account_admin, true)
      account.users.push(resource)

      order = account.add_order(price_plan, promotion_code, request.remote_ip)
      agents = User.get_agent_profiles_for_country(country_short)
      agents.each do |agent|
        NotificationMailer.new_signup(agent, resource, order, price_plan).deliver
      end

      if resource.active_for_authentication?
        set_flash_message :notice, :signed_up if is_navigational_format?
        sign_in(resource_name, resource)
        respond_with resource, :location => after_sign_up_path_for(resource)
      else
        set_flash_message :notice, :"signed_up_but_#{resource.inactive_message}" if is_navigational_format?
        expire_session_data_after_sign_in!
        respond_with resource, :location => after_inactive_sign_up_path_for(resource)
      end

    else
      @visitor_country = Country.get_by_short_code(country_short)
      @national_representatives = User.get_agent_profiles_for_country(country_short)
      @price_plan = Country.get_price_plan_by_country_and_id(country_short, price_plan_id)
      @countries = Country.sorted_by_language()

      if promotion_code_id.present?
        @promotion_code = @price_plan.promotion_codes.find(promotion_code_id)
      end

      session[:redirect_url] = signup_plan_path(price_plan)
      clean_up_passwords resource
      respond_with resource
    end
  end

  def update
    super
  end

  def resend_confirmation
    Devise::Mailer.confirmation_instructions(current_user).deliver
    redirect_to(member_dashboard_url, notice: t('alert.activation_email_sent', {:USER_EMAIL => current_user.email}))
  end

  def after_inactive_sign_up_path_for(resource)
    signed_up_url
  end

  ##
  # A user that has chosen a paid plan lands here when confirming the account
  # or signing in when the first subscription is inactive and membership fee has not been paid.
  def signup_confirmation_paid_plans
    return redirect_to(login_path) unless current_user

    @user = current_user
    country_short = @user.account.country_short
    @order = current_user.account.orders.last
    @order.set(:user_id, @user.id)
    @price_plan = Country.get_price_plan_by_country_and_id(country_short, @order.price_plan_id)
    @country = Country.where(short: country_short).first

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def signup_confirmation_free_plan
    return redirect_to(login_path) unless current_user

    @user = current_user
    @order = current_user.account.orders.last
    @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)

    @order.update_attributes(state: 'success', completed_at: Time.now.utc, user_id: @user.id)
    subscription = @user.account.add_subscription(@price_plan, @order)
    subscription.activate
    @user.account.finish_registration()
    @user.account.set_roles(['trial_member'])

    NotificationMailer.welcome_trial(@user).deliver

    respond_to do |format|
      format.html {redirect_to(member_dashboard_url)}
    end
  end

  ##
  # Is replacing cancel sign up. Instead of removing account and user
  # when a User cancel a paid sign up they are converted into trial
  # members instead.
  def skip_to_dashboard
    account = current_user.account
    order = account.orders.first
    original_price_plan = Country.get_price_plan_by_country_and_id(account.country_short, order.price_plan_id)
    trial_price_plan = Country.get_trial_plan_for_country(account.country_short)

    order.update_attributes(
      state: 'success',
      completed_at: Time.now.utc,
      user_id: current_user.id,
      price_plan_id: trial_price_plan.id,
      total_amount: 0,
      kind: 'free',
      note: "Subscription converted from paid to trial on signup. Original chosen price plan id #{original_price_plan.nil? ? 'No price plan found' : original_price_plan.id}"
    )

    subscription = account.add_subscription(trial_price_plan, order)
    subscription.activate
    account.finish_registration
    account.set_roles(['trial_member'])

    NotificationMailer.welcome_trial(current_user).deliver
    agents = User.get_agent_profiles_for_country(account.country_short)
    agents.each do |agent|
      NotificationMailer.trial_instead_of_paid(agent, current_user, order, original_price_plan).deliver
    end

    respond_to do |format|
      format.html {redirect_to(member_dashboard_path)}
    end
  end

  def cancel_signup
    begin
      event = {event: 'Terminated account from cancel signup', current_user: current_user.name, account_id: params[:id]}
      EventLog.create(event)
    rescue => e
      Rails.logger.error "Error when creating log event: #{e.inspect}"
    end

    sign_out(current_user)
    Account.terminate_account(params[:id])

    respond_to do |format|
      format.html {redirect_to(signup_cancelled_path)}
    end
  end

  def signup_cancelled
    respond_to do |format|
      format.html
    end
  end

  private

  def resource_params
    params.require(:user).permit(:name, :email, :password, :password_confirmation, :terms_and_conditions)
  end
end
