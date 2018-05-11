# encoding: UTF-8
class Payment::SubscriptionsController < ApplicationController
  include Payment::PricePlansHelper
  include ActiveMerchant::Billing::Integrations
  ActionView::Base.send(:include, ActiveMerchant::Billing::Integrations::ActionViewHelper)
  filter_access_to :all
  layout 'dashboard'

  def upgrade
    @user = current_user
    @order = Order.new(
      upgrade: true,
      renewal: false
    )
    @price_plans = Country.get_paid_plans_for_country(current_user.account.country_short)

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def renew
    @user = current_user
    @order = Order.new(
      upgrade: false,
      renewal: true
    )
    @price_plans = Country.get_paid_plans_for_country(current_user.account.country_short)

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def special_renewal
    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def activate_special_renewal
    locale = 'US'

    uuid = cookies[:intervac_user]
    u_locale = CookieJar.where(uuid: uuid).first.locale

    if Rails.application.config.paypal_locales.include?(u_locale) then
      locale = u_locale
    end

    order = Order.create!(
      price_plan_id: nil,
      currency: 'EUR',
      total_amount: 49,
      promotion_code: nil,
      upgrade: false,
      renewal: true,
      state: 'started',
      ip_address: request.remote_ip,
      country_short: locale, #SPECIAL RENEWAL
      order_number: Order.make_order_number(locale), #SPECIAL RENEWAL
      express_subject: Rails.application.config.paypal_options[:subject]
    )

    express_gateway = Order.paypal_express_gateway(order.express_subject)

    response = express_gateway.setup_purchase(order.price_in_cents,
      :ip                   => request.remote_ip,
      :return_url           => receive_special_renewal_token_subscriptions_url(order),
      :cancel_return_url    => cancelled_order_url(order),
      :currency             => "EUR",
      :description          => "Special renewal",
      :items                => [{ :name => t('payment.intervac_membership'), :quantity => "1", :amount => 4900, :description => "Special renewal" }],
      :allow_guest_checkout => true,
      :locale               => locale
    )

    redirect_to express_gateway.redirect_url_for(response.token)
  end

  def receive_special_renewal_token
    order = Order.find(params[:id])
    order.express_token=(params[:token])
    express_gateway = Order.paypal_express_gateway(order.express_subject)
    paypal_details = express_gateway.details_for(params[:token])

    begin
      PaypalDetail.log_details(params, paypal_details, order, 'receive_special_renewal_token')
    rescue => e
      NotificationMailer.oddity("Could not log PayPal details in receive_special_renewal_token. Error #{e}").deliver
    end

    error_code_token_already_used = "10415"
    respond_to do |format|
      if (paypal_details.params['ack'] == "Failure" or paypal_details.payer_id.nil?) and paypal_details.params['error_codes'] != error_code_token_already_used
        order.update_attributes(state: 'failed', express_token: params[:token], express_payer_id: paypal_details.payer_id)
        format.html { redirect_to(action: 'failure') }
      elsif paypal_details.params['ack'] == "Success"
        order.update_attributes(state: 'completed', express_token: params[:token], express_payer_id: paypal_details.payer_id)
        if order.save && order.purchase
          order.update_attributes(kind: 'paypal', state: 'success', completed_at: Time.now.utc)
          flash[:notice] = t('payment.special_renewal_success')
          format.html { redirect_to root_path }
        else
          return redirect_to special_renewal_subscriptions_path
        end
      end
    end
  end

  def cancelled
    @user = current_user
    @order = Order.find(params[:order_id])
    @order.update_attributes(state: 'cancelled',completed_at: Time.now.utc)
    @order.update_attributes(user_id: @user.id, account_id: @user.account_id) if @user

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def promotion_code
    code = params[:promotion_code].upcase

    country_short = current_user.account.country_short
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

  ##
  # Builds a correct order for renewals and upgrades.
  def setup_order
    @user = current_user
    country_short = current_user.account.country_short
    total_amount = 0
    promotion_code = false
    @price_plan = false

    if params[:promotion_code] && params[:price_plan_id]
      country = Country.where(short: country_short).first
      @price_plan = country.price_plans.find(params[:price_plan_id])

      if params[:promotion_code].present?
        code = params[:promotion_code].upcase
        promotion_code = @price_plan.promotion_codes.where(code: code).first
      end

      if promotion_code.nil?
        @price_plans = Country.get_paid_plans_for_country(current_user.account.country_short)
        @no_promotion_code = true
        @order = Order.new(
          upgrade: params[:upgrade],
          renewal: params[:renewal]
        )

        return render(action: 'upgrade', layout: 'registration') if params[:upgrade] == "true"
        return render(action: 'renew', layout: 'registration') if params[:renewal] == "true"
        return render(layout: 'registration')
      else

        if params[:promotion_code].blank?
          promotion_code = nil
        end

        base_price = params[:renewal] == "true" ? renew_or_base_price(@user, @price_plan) : @price_plan.base_price
        total_amount = promotion_code ? promotion_code.discounted_price.to_f : base_price

        if @price_plan.country.paypal_email.blank?
          express_subject = Rails.application.config.paypal_options[:subject]
        else
          express_subject = @price_plan.country.paypal_email
        end

        @order = Order.create!(
          price_plan_id: @price_plan.id,
          currency: @price_plan.country.currency,
          total_amount: total_amount,
          promotion_code: promotion_code.nil? ? nil : promotion_code.code,
          upgrade: params[:upgrade],
          renewal: params[:renewal],
          state: 'started',
          ip_address: request.remote_ip,
          country_short: @user.account.country_short,
          order_number: Order.make_order_number(@price_plan.country.short),
          express_subject: express_subject,
          user_id: @user.id
        )

        redirect_to payment_options_url(@order)
      end
    end
  end


  def payment_options
    @user = current_user
    @order = Order.find(params[:order_id])
    @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)
    @country = Country.where(short: @user.account.country_short).first

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  ##
  # Used by agents and admins to upgrade a user membership
  def upgrade_account_as_agent

    @account = Account.find(params[:account_id])
    @contact = @account.contact
    @price_plans = Country.get_paid_plans_for_country(@account.country_short)
    @order_kind = 'upgrade'

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  ##
  # Used by agents and admins to renew a user membership
  def renew_account_as_agent
    @account = Account.find(params[:account_id])
    @contact = @account.contact
    @price_plans = Country.get_paid_plans_for_country(@account.country_short)
    @order_kind = 'renewal'

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  def do_upgrade_or_renewal_as_agent
    @account = Account.find(params[:account_id])
    @price_plan = Country.get_price_plan_by_country_and_id(@account.country_short, params[:price_plan_id])

    case params[:order_kind]
    when 'upgrade'
      @order = Order.create_agent_order(@price_plan, 'upgrade', @account, current_user, request)
    when 'renewal'
      @order = Order.create_agent_order(@price_plan, 'renewal', @account, current_user, request)
    else
      render(redirect_to(account_path(@account)))
      return
    end

    if @order
      subscription = @account.add_subscription(@price_plan, @order)
      subscription.activate
      @account.finish_registration
      @account.remove_restrictions_for_users
    end

    respond_to do |format|
      if @order
        format.html {redirect_to(upgraded_account_subscriptions_path(@account))}
      else
        format.html {render(action: :upgrade_account_as_agent)}
      end
    end
  end

  def account_upgraded_or_renewed_as_agent
    @account = Account.find(params[:account_id])
    @contact = @account.contact
    @subscription = @account.current_subscription

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end

  ##
  # Shows the full details of a subscription
  def full_details
    @account = Account.find(params[:account_id])
    @subscription = @account.subscriptions.find(params[:id])
    @order = Order.find(@subscription.order_id)

    if @order.user_id
      @user = User.find(@order.user_id)
    end

    if @order.by_agent
      @agent = User.find(@order.by_agent)
    end

    if @order.price_plan_id
      @price_plan = Country.where(:"price_plans._id" => @order.price_plan_id).first.price_plans.find(@order.price_plan_id)
    end

    respond_to do |format|
      format.html {render(layout: 'management')}
    end
  end
end
