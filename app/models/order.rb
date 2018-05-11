class Order
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  belongs_to :account
  embeds_many :transactions, :class_name => 'OrderTransaction'
  
  field :order_number,          type: String, default: nil
  field :currency,              type: String, default: 'EUR'
  field :total_amount,          type: Float, default: 0
  field :state,                 type: String, default: 'unconfirmed'
  field :raw_data,              type: String, default: ''
  field :express_token,         type: String, default: ''
  field :express_payer_id,      type: String, default: ''
  field :express_subject,       type: String, default: ''
  field :ip_address,            type: String, default: ''
  field :promotion_code,        type: String, default: ''
  field :renewal,               type: Boolean, default: false
  field :upgrade,               type: Boolean, default: false
  field :kind,                  type: String, default: nil
  field :price_plan_id,         type: BSON::ObjectId, default: nil
  field :completed_at,          type: DateTime, default: nil
  field :unique_payment_id,     type: String, default: nil
  field :country_short,         type: String, default: 'www'
  field :user_id,               type: BSON::ObjectId, default: nil
  field :by_agent,              type: BSON::ObjectId, default: nil
  field :mail_sent,             type: Boolean, default: false
  field :note,                  type: String, default: ''
  
  
  def self.create_agent_order(price_plan, kind, account, user, request)

    upgrade = false
    renewal = false

    if kind == 'upgrade'
      upgrade = true
    end

    if kind == 'renewal'
      renewal = true
    end

    begin

      order = Order.create!(
        price_plan_id: price_plan.id,
        currency: price_plan.country.currency,
        total_amount: price_plan.base_price,
        upgrade: upgrade,
        renewal: renewal,
        state: 'completed',
        ip_address: request.remote_ip,
        country_short: price_plan.country.short,
        order_number: Order.make_order_number(price_plan.country.short),
        user_id: account.account_owner,
        by_agent: user.id
      )
      
    rescue Exception => e
      order = false      
    end

    order
  end
  
  def purchase
    response = process_purchase
    transactions.create!(:action => "purchase", :amount => self.price_in_cents, :response => response)
    self.update_attribute(:completed_at, Time.now) if response.success?
    if response.success?
      return true
    end
    error_code_token_already_used = "10415"
    if response.params['error_codes'] == error_code_token_already_used
      return true
    end
    return false
  end
  
  def price_in_cents
    (self.total_amount*100).round
  end
  
  def express_token=(token)
    self[:express_token] = token
    if new_record? && !token.blank?

      express_gateway = Order.paypal_express_gateway(self.express_subject)
      details = express_gateway.details_for(token)
      self.express_payer_id = details.payer_id
    end
  end

  ##
  #
  def self.make_order_number(country_short)
    order_number = "#{country_short}-#{sprintf("%08d", rand(99999999))}"
    return order_number
  end

  ##
  # Creates a PayPal gateway with the provided subject
  def self.paypal_express_gateway(subject)
    paypal_options = {}
    paypal_options.merge!(Rails.application.config.paypal_options)
    paypal_options[:subject] = subject
    ActiveMerchant::Billing::PaypalExpressGateway.new(paypal_options)  
  end


  def self.validate_promotion_code_for_country(code, country_short)

    begin
      country = Country.get_by_short(country_short)
      valid = country.validate_promotion_code(code)
      return valid
    rescue Exception => e
      
    end
    
    return false
  end


  private
  
  def process_purchase

    express_gateway = Order.paypal_express_gateway(express_subject)

    express_gateway.purchase(self.price_in_cents, {
      :ip => ip_address,
      :token => express_token,
      :payer_id => express_payer_id,
      :currency => currency,
      :notify_url => 'http://intervac-homeexchange.com/orders/paypal_ipn'
      })
  end
  
  
  def self.number_of_orders(period = 'all')
    
    if period == 'month' then
      return self.where(:created_at.gt => Time.now.at_beginning_of_month.utc).count()
    end
    
    if period == 'year' then
      return self.where(:created_at.gt => Time.now.at_beginning_of_year.utc).count()
    end
    
    return self.all.count()
  end
  
  
  def self.as_csv
    
    ipn_logs = self.only(:params_data, :created_at)
    ipn_list = CSV.generate({:col_sep => '|'}) do |csv|
      csv << %w(mc_gross created_at)
      
      ipn_logs.each do |ipn_log|
        csv << [ipn_log.params_data['mc_gross'], ipn_log.created_at]
      end
    end
    
    return ipn_list
  end
  
end
