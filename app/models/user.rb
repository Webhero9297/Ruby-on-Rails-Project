# encoding: utf-8
class User
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  belongs_to :account

  embeds_one :agent_profile, :class_name => "AgentProfile"

  attr_accessor :login, :terms_and_conditions, :provider, :fb_graph_id

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable
  devise :invitable, :omniauthable, :database_authenticatable, :token_authenticatable, :rememberable, :registerable, :recoverable, :trackable, :validatable, :encryptable, :encryptor => :restful_authentication_sha1

  field :name,                  type: String
  field :roles,                 type: Array, default: ['member']
  field :account_admin,         type: Boolean, default: false
  field :provider,              type: String, default: nil
  field :fb_graph_id,           type: String, default: nil
  field :user_login,            type: String, default: Devise.friendly_token.first(8) # Will only be used for legacy purposes for members that log in with their member number or choosen log in.
  field :device_token,          type: String, default: nil
  field :device_type,           type: String, default: nil
  field :secondary_email,       type: String, default: nil
  field :terminated,            type: Boolean, default: false

  ## Database authenticatable
  field :email,              :type => String, :null => false
  field :encrypted_password, :type => String, :null => false

  ## Recoverable
  field :reset_password_token,   :type => String
  field :reset_password_sent_at, :type => Time

  ## Rememberable
  field :remember_created_at, :type => Time

  ## Trackable
  field :sign_in_count,       :type => Integer
  field :current_sign_in_at,  :type => Time
  field :last_sign_in_at,     :type => Time
  field :current_sign_in_ip,  :type => String
  field :last_sign_in_ip,     :type => String

  ## Devise confimration settings
  field :confirmation_token,   :type => String
  field :confirmed_at,         :type => Time
  field :confirmation_sent_at, :type => Time

  ## Encryptable
  field :password_salt, :type => String

  # Token authenticatable
  field :authentication_token, :type => String

  ## Invitable
  field :invitation_token, :type => String
  field :invitation_sent_at, :type => Time
  field :invitation_accepted_at, :type => Time
  field :invitation_limit, :type => Integer
  field :invited_by_type, :type => String

  validates_length_of :name, allow_blank: false, minimum: 4, maximum: 40
  validates_acceptance_of :terms_and_conditions, :allow_nil => false, :on => :create

  def set_as_ambassador
    self.roles.include?('ambassador') ? self.roles.delete('ambassador') : self.roles << 'ambassador'
    self.save
  end

  def set_name_and_email(params)
    self.name  = params[:name]
    self.email = params[:email]

    self.valid? ? self.save : false
  end


  def self.find_for_facebook_oauth(auth, signed_in_resource=nil)
    User.where(
      :provider => auth.provider, :fb_graph_id => auth.uid
    ).first
  end


  def self.find_by_email(email)
    User.where(:email => email).first
  end

  def link_user_to_facebook(fb_graph_id)
    self['provider'] = "facebook"
    self['fb_graph_id'] = fb_graph_id
    self.save!
  end

  def self.find_for_database_authentication(conditions)
    login = conditions.delete(:login)
    self.any_of({ :user_login =>  /^#{Regexp.escape(login)}$/i }, { :email =>  /^#{Regexp.escape(login)}$/i }).first
  end

  def self.get_agent_profiles_for_country(country)
    self.where('agent_profile.agent_for.short' => {'$in' => [country.upcase]}).order_by(['agent_profile.position', :asc])
  end

  ##
  # Remove trial and or restricted and add member
  def set_as_member
    self.roles.delete('restricted')
    self.roles.delete('trial_member')
    if not self.roles.include?('member')
      self.roles.push('member')
    end
    self.save
  end

  def upgrade_to_agent
    self.add_to_set(:roles, "agent")
    self.create_agent_profile(
      email: self.account.contact.email,
      address: self.account.contact.address,
      postal_town: self.account.contact.postal_town,
      postal_code: self.account.contact.postal_code,
      telephone: self.account.contact.telephone,
      mobile: self.account.contact.mobile,
      skype: self.account.contact.skype,
      website: self.account.contact.website
    )
  end

  def is_agent
    roles.include?('agent')
  end

  def is_admin
    roles.include?('admin')
  end

  def is_member
    roles.include?('member')
  end

  def is_trial
    roles.include?('trial_member')
  end

  def self.reload_agent_locales
    agents = User.where(roles: 'agent')
    agents.each do |agent|
      agent.agent_profile.reload_locales
    end
  end

  def self.build_account_invite(params)
    generated_password = Devise.friendly_token.first(10)

    self.new(
      name: params[:user][:name],
      email: params[:user][:email],
      account_admin: false,
      roles: ['member'],
      password: generated_password,
      password_confirmation: generated_password,
    )
  end

  def role_symbols
    (roles || []).map(&:to_sym)
  end

  def has_role(role)
    role_symbols.include? role
  end

  ##
  # Scopes data mapper style. Methods that returns criteria can be treated as chainable scopes as well.
  class << self
    def has_permission(asking_user)
      if asking_user.has_role(:agent) or asking_user.has_role(:admin)
        return where()
      end

      where(account_id: asking_user.account_id)
    end

    def agent_profile
      where(roles: 'agent').only(:name, :email, :user_login, :agent_profile, :country_short, :account_id)
    end
  end

  ##
  # Default scope to filter terminated users
  default_scope where(terminated: false)
end
