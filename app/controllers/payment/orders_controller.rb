# encoding: UTF-8
class Payment::OrdersController < ApplicationController
  include ActiveMerchant::Billing::Integrations
  ActionView::Base.send(:include, ActiveMerchant::Billing::Integrations::ActionViewHelper)

  filter_access_to :express, :new, :create, :edit, :update, :success, :failure, :invoice, :save_invoice, :response_from_france, :sage_pay_setup, :sage_pay_confirmation, :sage_pay_notification, :french_payment_setup, :french_payment_confirmation, :generic_offline_payment_confirmation, :set_as_restricted
  layout 'dashboard'
  skip_before_filter :geo_and_user_check, :only => [:paypal_ipn, :french_payment_notification, :sage_pay_confirmation]
  skip_before_filter :verify_authenticity_token, :only => [:paypal_ipn, :french_payment_notification, :sage_pay_confirmation]

  def express
    order = Order.find(params[:id])

    session[:order_id] = order.id
    return_dest = edit_order_url(order)

    price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, order.price_plan_id)

    locale = 'US'
    if Rails.application.config.paypal_locales.include?(current_user.account.country_short) then
      locale = current_user.account.country_short
    end

    if not order.express_subject.blank?
      express_subject = order.express_subject
    else
      express_subject = Rails.application.config.paypal_options[:subject]
    end

    express_gateway = Order.paypal_express_gateway(express_subject)

    response = express_gateway.setup_purchase(order.price_in_cents,
      :ip                   => request.remote_ip,
      :return_url           => return_dest,
      :cancel_return_url    => cancelled_order_url(order),
      :currency             => order.currency,
      :description          => price_plan.name,
      :items                => [{ :name => t('payment.intervac_membership'), :quantity => "1", :amount => order.price_in_cents, :description => price_plan.name }],
      :allow_guest_checkout => true,
      :locale               => locale
    )
    redirect_to express_gateway.redirect_url_for(response.token)
  end

  def new
    respond_to do |format|
      format.html
    end
  end

  def create
    ### DEPRECATED???????
    promotion_code = nil

    # Check if a promotion code is used
    if params[:order][:promotion_code] != nil then
      order_promotion_code = params[:order][:promotion_code].upcase
      price_plan = Country.where(:"price_plans.promotion_codes.code" => order_promotion_code).first.price_plans.where(:"promotion_codes.code" => order_promotion_code).first
      promotion_code = price_plan.promotion_codes.where(code: order_promotion_code).first
    else
      price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, params[:order][:price_plan_id])
    end

    @account = current_user.account

    # Creates and builds the order object
    @order = Order.new(order_params)
    @order.account_id = @account.id
    @order.currency = price_plan.country.currency
    @order.country_short = price_plan.country.short
    @order.price_plan_id = price_plan.id
    @order.order_number = Order.make_order_number(price_plan.country.short)

    if price_plan.country.paypal_email.blank?
      @order.express_subject = Rails.application.config.paypal_options[:subject]
    else
      @order.express_subject = price_plan.country.paypal_email
    end

    # Checks if the order is a renewal, upgrade or new sign up.
    if @order.renewal == true or @order.upgrade then
      if promotion_code != nil
        @order.total_amount = price_plan.discounted_price.to_f
      else
        @order.total_amount = price_plan.renewal_price
      end
    else
      @order.total_amount = price_plan.base_price
    end

    if @order.save
      redirect_to(action: 'express', id: @order)
    else
      render(action: 'new')
    end
  end

  ##
  # The user lands here after sign up since the order already is
  # created or when revisiting an current renewal order that has not
  # been completed.
  def edit
    @user = current_user
    @order = Order.find(params[:id])
    @price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, @order.price_plan_id)

    if @price_plan.country.paypal_email.blank?
      @order.set(:express_subject, Rails.application.config.paypal_options[:subject])
    else
      @order.set(:express_subject, @price_plan.country.paypal_email)
    end

    express_gateway = Order.paypal_express_gateway(@order.express_subject)
    @paypal_details = express_gateway.details_for(params[:token])

    begin
      PaypalDetail.log_details(params, @paypal_details, @order, 'edit')
    rescue => e
      NotificationMailer.oddity("Could not log PayPal details in edit. Error #{e}").deliver
    end

    error_code_token_already_used = "10415"
    respond_to do |format|
      if (@paypal_details.params['ack'] == "Failure" or @paypal_details.payer_id.nil?) and @paypal_details.params['error_codes'] != error_code_token_already_used
        @order.update_attributes(state: 'failed', express_token: params[:token], express_payer_id: @paypal_details.payer_id)
        format.html { redirect_to(action: 'failure') }
      else
        @order.update_attributes(state: 'review', express_token: params[:token], express_payer_id: @paypal_details.payer_id)
        format.html {render(layout: 'registration')}
      end
    end
  end

  ##
  # The payment is completed by updating the order and inserting a
  # description on the membership account.
  def update
    @user = current_user
    @order = Order.find(params[:id])
    @price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, @order.price_plan_id)

    if @order.save
      if @order.purchase

        @order.update_attributes(kind: 'paypal', state: 'success', completed_at: Time.now.utc)
        @price_plan.mark_promotion_code_for_usage(@order)
        subscription = @user.account.add_subscription(@price_plan, @order)
        subscription.activate
        @user.account.finish_registration()

        redirect_to( action: 'success', id: @order )
      else
        redirect_to( action: 'failure', id: @order )
      end
    else
      render action: 'edit'
    end
  end

  def success
    @order = Order.find(params[:id])
    begin
      @user = User.find(@order.user_id)
    rescue Exception => e
      @user = current_user
    end

    @country = Country.where(short: @user.account.country_short).first
    @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)

    if @order.kind == 'paypal' then
      paypal_options = {}
      paypal_options.merge!(Rails.application.config.paypal_options)
      paypal_options[:subject] = @order.express_subject
      express_gateway = ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)
      @paypal_details = express_gateway.details_for(@order.express_token)

      @user.account.contact.update_attributes(
        address: @paypal_details.params['street1'],
        postal_town: @paypal_details.params['city_name'],
        postal_code: @paypal_details.params['postal_code']
      )

      @user.account.remove_restrictions_for_users
      NotificationMailer.success_payment(@order).deliver

      begin
        PaypalDetail.log_details({token: @order.express_token, PayerID: @order.express_payer_id}, @paypal_details, @order, 'success')
      rescue => e
        NotificationMailer.oddity("Could not log PayPal details sucess. Error #{e}").deliver
      end
    end

    if @order.kind == 'invoice' then
      @user.account.contact.update_attributes(
          address: @order.transactions.first.params['street'],
          postal_town: @order.transactions.first.params['city'],
          postal_code: @order.transactions.first.params['postal_code'],
          telephone: @order.transactions.first.params['phone']
        )
    end

    if @order.kind == 'va_solutions' or @order.kind == 'sage_pay'
      @user.account.remove_restrictions_for_users
    end

    if @order.mail_sent == false
      begin
        if @order.renewal or @order.upgrade
          NotificationMailer.membership_renewal(@user).deliver
        else
          NotificationMailer.welcome(@user).deliver
        end
      rescue => e
        NotificationMailer.oddity("Success mail notifications for new payment. Order #{@order.order_number}, Error: #{e}").deliver
      end

      @order.set(:mail_sent, true)
    end

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def failure
    @order = Order.find(params[:id])
    @country = Country.where(short: current_user.account.country_short).first
    @user = User.find(@order.user_id)
    @account = @user.account

    begin
      express_gateway = Order.paypal_express_gateway(@order.express_subject)
      @paypal_details = express_gateway.details_for(@order.express_token)
      PaypalDetail.log_details({token: @order.express_token, PayerID: @order.express_payer_id}, @paypal_details, @order, 'failure')
    rescue Exception => e
      NotificationMailer.oddity("Could not log PayPal details in failure. Error #{e}").deliver
    end

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def invoice
    @user = current_user
    @order = Order.find(params[:id])
    @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)
    @country = Country.where(short: @user.account.country_short).first

    if @order.renewal or @order.upgrade
      @invoice = InvoiceForm.new(
        street: @user.account.contact.address,
        city: @user.account.contact.postal_town,
        postal_code: @user.account.contact.postal_code,
        country: @user.account.country_short,
        phone: @user.account.contact.telephone.nil? ? @user.account.contact.mobile : @user.account.contact.telephone
      )
    else
      @invoice = InvoiceForm.new
    end

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  ##
  # Takes care of the invoice orders.
  # TODO Could be merged with update.
  def save_invoice
    @invoice = InvoiceForm.new(params[:address])
    @user = current_user
    @order = Order.find(params[:id])
    @country = Country.where(short: @user.account.country_short).first
    @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)

    if @invoice.valid?

      @order.update_attributes(
        kind: 'invoice',
        state: 'success',
        raw_data: params[:address],
        completed_at: Time.now.utc
      )

      current_expire_date = 1.year.ago.utc

      if @order.upgrade or @order.renewal
        begin
          current_expire_date = @user.account.current_subscription.expires_at
        rescue => e
        end
      end

      subscription = @user.account.add_subscription(@price_plan, @order)
      # If we do not have a current subscription we must activate this one.
      if @user.account.current_subscription.nil?
        subscription.activate
      end

      @order.transactions.create!(:action => "invoice request", :success => true, :amount => @order.price_in_cents, :params => params[:address])
      @user.account.finish_registration()
      @price_plan.mark_promotion_code_for_usage(@order)

      agents = User.get_agent_profiles_for_country(@user.account.country_short)
      agents.each do |agent|
        begin
          NotificationMailer.invoice_payment(agent, @user, @order, @price_plan).deliver
        rescue => e
          NotificationMailer.oddity("Could not send invoice mail to agent. #{@order.order_number}, Error: #{e}").deliver
        end
      end

      # Makes sure the member role is set and that trial and or
      # restricted is removed
      begin
        account = current_user.account
        account.users.each do |user|
          user.set_as_member
        end
      rescue
      end

      # If the country does not have automatic activation the account
      # gets awaiting status true and the users recives restricted
      # access on account confirmation
      if @country.allow_direct_access
        subscription.activate
        @user.account.remove_restrictions_for_users
      else
        @user.account.set(:awaiting_access, true)
        if current_expire_date < Time.now.utc
          @user.account.restrict_access_for_users
        end
      end

      redirect_to( action: 'success', id: @order )
    else
      render( action: 'invoice', layout: 'registration')
    end
  end

  def paypal_ipn
    notification = Paypal::Notification.new(request.raw_post)

    if notification.acknowledge
      begin
        if notification.complete?
          PaypalIpnLog.create(raw_data: notification.raw, params_data: notification.params)
        else
          NotificationMailer.oddity("Failed to verify Paypal's notification, please investigate").deliver
        end
      rescue => e
        begin
          NotificationMailer.oddity("PayPalIPN: Params: #{notification.params} Error:#{e}").deliver
        rescue => e
          NotificationMailer.oddity("Error with PayPalIPN: #{e}").deliver
        end
      end
    end

    render :nothing => true
  end

  def sage_pay_setup
    @uk_details_payment_form = UkDetailsPaymentForm.new
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def sage_pay_confirmation
    @order = Order.find(params[:id])
    @details = params[:uk_details_payment_form]
    @account = current_user.account
    @price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, @order.price_plan_id)
    @uk_details_payment_form = UkDetailsPaymentForm.new(uk_details_payment_form_params)
    @order.update_attributes(
      kind: 'sage_pay',
      country_short: 'gb',
    )
    @order.transactions.create!(:action => "payment request", :success => true, :amount => @order.price_in_cents, :params => params[:uk_details_payment_form])

    respond_to do |format|
      if @uk_details_payment_form.valid?
        format.html {render(layout: 'registration', layout: 'registration')}
      else
        format.html {render(action: 'sage_pay_setup', layout: 'registration')}
      end
    end
  end

  def sage_pay_notification
    @user = current_user
    @order = Order.find(params[:id])
    @price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, @order.price_plan_id)

    order_number = @order.order_number
    @order.update_attributes(
      raw_data: params,
      unique_payment_id: order_number,
      state: 'success',
      completed_at: Time.now.utc
    )

    @price_plan.mark_promotion_code_for_usage(@order)
    subscription = @user.account.add_subscription(@price_plan, @order)
    subscription.activate
    @user.account.finish_registration()
    @order.transactions.create!(:action => "payment response", :success => true, :amount => @order.price_in_cents, :params => params)

    respond_to do |format|
      format.html {redirect_to(success_order_path(@order.id))}
    end
  end

  def french_payment_setup
    @fr_details_payment_form = FrDetailsPaymentForm.new
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html {render(layout: 'registration')}
    end
  end

  def french_payment_confirmation
    @order = Order.find(params[:id])
    @details = params[:fr_details_payment_form]
    @account = current_user.account
    @price_plan = Country.get_price_plan_by_country_and_id(current_user.account.country_short, @order.price_plan_id)
    @fr_details_payment_form = FrDetailsPaymentForm.new(fr_details_payment_form_params)
    @order.transactions.create!(:action => "payment request", :success => true, :amount => @order.price_in_cents, :params => params[:fr_details_payment_form])

    respond_to do |format|
      if @fr_details_payment_form.valid?
        format.html {render(layout: 'registration')}
      else
        format.html {render(action: 'french_payment_setup', layout: 'registration')}
      end
    end
  end

  def french_payment_notification
    NotificationMailer.payment_notification(params, 'attempt').deliver

    begin
      @order = Order.find(params[:OrderID])
      @user = User.find(@order.user_id)
      @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)
    rescue Exception => e
      NotificationMailer.payment_notification(params, 'failed', e.inspect).deliver
    end

    respond_to do |format|
      if params[:PaymentStatus] == '00' or params[:ResponseCode] == '00'
        @order.update_attributes(
          kind: 'va_solutions',
          country_short: 'fr',
          raw_data: params,
          unique_payment_id: params[:UniquePaymentID],
          state: 'success',
          completed_at: Time.now.utc
        )

        @price_plan.mark_promotion_code_for_usage(@order)
        subscription = @user.account.add_subscription(@price_plan, @order)
        subscription.activate
        @user.account.finish_registration()
        @order.transactions.create!(:action => "payment response", :success => true, :amount => @order.price_in_cents, :params => params)

        @user.account.remove_restrictions_for_users

        if @order.mail_sent == false
          begin
            if @order.renewal or @order.upgrade
              NotificationMailer.membership_renewal(@user).deliver
            else
              NotificationMailer.welcome(@user).deliver
            end
            NotificationMailer.french_payment_notification(@user, @order, @price_plan).deliver
          rescue => e
            NotificationMailer.oddity("Error:#{e}. Backtrace: #{e.backtrace.join('\n')}").deliver
          end
          @order.set(:mail_sent, true)
        end

        format.html {render :nothing => true, status: 200}
      else
        format.html {render :nothing => true}
      end
    end
  end

  def generic_offline_payment_confirmation
    @user = current_user
    @order = Order.find(params[:id])
    @country = Country.where(short: @user.account.country_short).first
    @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)

    @order.update_attributes(
      kind: 'offline_payment',
      state: 'success',
      raw_data: params,
      completed_at: Time.now.utc
    )

    current_expire_date = 1.year.ago.utc
    if @order.upgrade or @order.renewal
      begin
        current_expire_date = @user.account.current_subscription.expires_at
      rescue
      end
    end

    subscription = @user.account.add_subscription(@price_plan, @order)
    # If we do not have a current subscirption we must activate this one.
    if @user.account.current_subscription.nil?
      subscription.activate
    end

    @order.transactions.create!(:action => "offline payment request", :success => true, :amount => @order.price_in_cents, :params => params)
    @user.account.finish_registration()
    @price_plan.mark_promotion_code_for_usage(@order)

    agents = User.get_agent_profiles_for_country(@user.account.country_short)
    agents.each do |agent|
      begin
        NotificationMailer.offline_payment(agent, @user, @order, @price_plan).deliver
      rescue => e
        NotificationMailer.oddity("Could not send generic offline payment notification: #{e}").deliver
      end
    end

    # If the country does not have automatic activation the account
    # gets awaiting status true and the users recives restricted
    # access on account confirmation
    if @country.allow_direct_access
      subscription.activate
      @user.account.remove_restrictions_for_users
    else
      @user.account.set(:awaiting_access, true)
      if current_expire_date < Time.now.utc
        @user.account.restrict_access_for_users
      end
    end

    respond_to do |format|
      format.html {redirect_to(success_order_path(@order.id))}
    end
  end

  def set_as_restricted
    @user = current_user
    @order = Order.find(params[:id])

    begin
      # Something went wrong with either upgrade or renewal.
      # If current subscription exists just redirect back.
      if current_user.account.days_until_expire > 0
        NotificationMailer.oddity("Order could not be completed. #{@order.order_number}. User sent to dashboard").deliver
        redirect_to(member_dashboard_path)
        return
      end
    rescue
    end

    @country = Country.where(short: @user.account.country_short).first
    @price_plan = Country.get_price_plan_by_country_and_id(@user.account.country_short, @order.price_plan_id)

    subscription = @user.account.add_subscription(@price_plan, @order)
    subscription.activate
    @order.transactions.create!(:action => "offline payment request", :success => true, :amount => @order.price_in_cents, :params => params)
    @user.account.finish_registration()
    @price_plan.mark_promotion_code_for_usage(@order)

    @user.account.set(:awaiting_access, true)
    @user.account.restrict_access_for_users

    agents = User.get_agent_profiles_for_country(@user.account.country_short)
    agents.each do |agent|
      begin
        NotificationMailer.offline_payment(agent, @user, @order, @price_plan).deliver
      rescue => e
        NotificationMailer.oddity("Could not send offline payment notification for set as restricted. Error: #{e}").deliver
      end
    end

    respond_to do |format|
      format.html { redirect_to(member_dashboard_path) }
    end
  end

  private

  def order_params
    params.require(:order).permit(:currency, :total_amount, :state, :raw_data, :express_token, :express_payer_id, :ip_address, :promotion_code, :renewal, :upgrade, :kind, :price_plan_id, :completed_at, :unique_payment_id, :country_short, :account_id, :user_id)
  end

  def uk_details_payment_form_params
    params.require(:uk_details_payment_form).permit(:first_name, :last_name, :phone, :street, :city, :postal)
  end

  def fr_details_payment_form_params
    params.require(:fr_details_payment_form).permit(:first_name, :last_name, :phone, :street, :city, :postal)
  end
end
