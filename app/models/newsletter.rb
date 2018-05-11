require 'csv'
class Newsletter
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :activation_code,     type: String
  field :email,               type: String
  field :user_agent,          type: String, default: nil
  field :language,            type: String, default: nil
  field :user_type,           type: String, default: 'guest'
  field :country_short,       type: String, default: nil
  field :ip_address,          type: String, default: nil
  field :user_id,             type: BSON::ObjectId, default: nil
  field :account_id,          type: BSON::ObjectId, default: nil
  field :activated_at,        type: DateTime, default: nil
  
  before_save :create_activation_code
  validates_presence_of :email, :message => 'You must provide an email address.'
  validates_uniqueness_of :email, :message => 'The email address you provided already has a newsletter subscription.'
  validates_format_of :email, :with => /^([^\s]+)((?:[-a-z0-9]\.)[a-z]{2,})$/i, :message => 'You must provide a valid email address.'
  
  def self.activate(activation_code)
    newsletter = self.where(activation_code: activation_code).first
    if newsletter and newsletter.activated_at.nil?
      newsletter.update_attribute(:activated_at, Time.now.utc)
      return true
    end
    
    return false
  end
  
  
  def self.create_newsletter(user, params, request)
    
    geoip = GeoIP.new("#{Rails.root}/lib/GeoIP.dat")
    country = geoip.country(request.env['REMOTE_ADDR'])
    
    newsletter = Newsletter.new(
      email: params[:email],
      user_type: user.nil? ? 'guest' : 'member',
      user_id: user.nil? ? nil : user.id,
      account_id: user.nil? ? nil : user.account.id,
      country_short: country.country_code2.nil? ? country.country_code2 : 'www',
      user_agent: request.env['HTTP_USER_AGENT'],
      language: request.env['HTTP_ACCEPT_LANGUAGE'][0,2],
      ip_address: request.env['REMOTE_ADDR'],
      activated_at: nil
    )
    
    
    return newsletter
  end
  
  
  def self.number_of_subscribers(period = 'all')
    
    if period == 'month' then
      return self.where(:created_at.gt => Time.now.at_beginning_of_month.utc).count()
    end
    
    if period == 'year' then
      return self.where(:created_at.gt => Time.now.at_beginning_of_year.utc).count()
    end
    
    return self.all.count()
  end
  
  
  def self.number_of_activations(period = 'all')
    
    if period == 'month' then
      return self.where(:activated_at.gt => Time.now.at_beginning_of_month.utc).count()
    end
    
    if period == 'year' then
      return self.where(:activated_at.gt => Time.now.at_beginning_of_year.utc).count()
    end
    
    return self.where(:activated_at.ne => nil).count()
  end
  
  
  def self.as_csv
    
    subscribers = self.where(:activated_at.ne => nil)
    email_list = CSV.generate({:col_sep => ';'}) do |csv|
      csv << %w(Email UserType ActivationCode ActivatedAt CreatedAt UpdatedAt)

      subscribers.each do |subscriber|
        csv << [subscriber.email, subscriber.user_type, subscriber.activation_code, subscriber.activated_at, subscriber.created_at, subscriber.updated_at]
      end
    end
    
    return email_list
  end
  
  private
  
  def create_activation_code
    self.activation_code = SecureRandom.hex(16)
  end
  
end
