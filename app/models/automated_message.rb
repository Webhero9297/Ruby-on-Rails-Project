class AutomatedMessage
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  field :kind,                type: String
  field :name,                type: String
  field :subject,             type: String, default: 'Message from Intervac Home Exchange'
  field :message,             type: String
  field :countries,           type: Array, default: []
  field :days,                type: Integer, default: 0
  field :when,                type: String, default: 'before' # Future feature
  field :action,              type: String, default: 'expires' # Future feature
  field :has_schedule,        type: Boolean, default: true # Future feature
  field :created_by,          type: BSON::ObjectId
  field :last_edited_by,      type: BSON::ObjectId
  field :send_copy_to_agent,  type: Boolean, default: false


  validates :subject, :length => { :minimum => 5, :maximum => 100, :message => 'Your message must have a subject' }
  validates :message, :length => { :minimum => 5, :maximum => 8000, :message => 'Your message must have body text' }
  validates :days, :countries, :presence => true

  ##
  # Updates a single message, takes two parameters, form params[:automated_message] and a user_id
  def update_message(params, user_id)

    self.name = AutomatedMessage.get_message_name(params[:kind])
    self.kind = params[:kind]
    self.subject = params[:subject]
    self.message = params[:message]
    self.days = params[:days]
    self.countries = params[:countries]
    self.last_edited_by = user_id
    self.send_copy_to_agent = params[:send_copy_to_agent]

    self
  end

  # Returns an array with all the different messages kinds
  def self.get_message_kinds

    kinds = []
    self.message_meta_data.each do |key, meta_data|
      kinds.push([meta_data["name"], key])
    end

    return kinds
  end


  def self.get_placeholders_for_message(message)
    if not message.blank?
      return self.message_meta_data[message]['placeholders']
    end

    return ""
  end


  def self.get_days_for_message(message)
    if not message.blank?
      return self.message_meta_data[message]['days']
    end

    return 0
  end



  def self.message_meta_data

    automated_messages = {
      "welcome" => {"name" => "Welcome Membership", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}', "days" => 0},
      "welcome_trial" => {"name" => "Welcome Trial Membership", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{NUMBER}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}', "days" => 0},
      "trial_expiration" => {"name" => "Trial Membership Expiration Notification", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{LISTING_ID}, %{SUBSCRIPTION_LINK}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}, %{EXPIRE_DAYS}, %{DEACTIVATION_DATE}', "days" => 0},
      "first_expiration_notification" => {"name" => "1st Expiration Notification", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{EXPIRE_DAYS}, %{DEACTIVATION_DATE}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}, %{LISTING_ID}', "days" => 14},
      "second_expiration_notification" => {"name" => "2nd Expiration Notification", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{EXPIRE_DAYS}, %{DEACTIVATION_DATE}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}, %{LISTING_ID}', "days" => 5},
      "third_expiration_notification" => {"name" => "3rd Expiration Notification", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{EXPIRE_DAYS}, %{DEACTIVATION_DATE}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}, %{LISTING_ID}', "days" => 14},
      "new_member_activation" => {"name" => "Activate a new member", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}', "days" => 0},
      "membership_renewal_activation" => {"name" => "Activate a renewed member", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{LISTING_ID}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}', "days" => 0},
      "renewal_thank_you" => {"name" => "Thank you for renewing", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{LISTING_ID}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}', "days" => 0},
      "green_light_reminder" => {"name" => "Green Light Reminder", "placeholders" => '%{FAMILY_NAME}, %{FAMILY_ID}, %{COUNTRY}, %{LOGIN}, %{LISTING_ID}, %{LAST_LOGIN_IN_DAYS}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}', "days" => 30},
      "welcome_home" => {"name" => "Welcome Home", "placeholders" => '%{FAMILY_NAME}, %{FEEDBACK_LINK}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_FAX}, %{MY_URL}, %{LISTING_ID}', "days" => 0},
      "exchange_dates_reminder" => {"name" => "Exchange Dates Reminder", "placeholders" => '%{FAMILY_NAME}, %{LISTING_ID}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_URL}, %{MY_COUNTRY}'},
      "reply_to_exchange_reminder" => {"name" => "Reply to Exchange Offer Reminder", "placeholders" => '%{FAMILY_NAME}, %{LISTING_ID}, %{MY_NAME}, %{MY_EMAIL}, %{MY_PHONE}, %{MY_URL}, %{MY_COUNTRY}'}
    }

  end


  # Returns an array with words describing when the actions should take place
  def self.get_whens
    kinds = [['Before', 'before'], ['After', 'after']]
  end

  # Returns an array with actions on when the message should be sent
  def self.get_actions
    kinds = [['Expires', 'expires'], ['Joined', 'joined']]
  end

  def self.get_message_name(wants_kind)

    kinds = self.get_message_kinds

    kinds.each do |kind|
      if kind[1] == wants_kind
        return kind[0]
      end
    end

    return nil
  end

  def self.get_default_message(kind)
    self.where(:kind => kind).where(:countries => 'default').first
  end

end
