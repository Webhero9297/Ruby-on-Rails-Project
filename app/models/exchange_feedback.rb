class ExchangeFeedback
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :first_exchange,            type: Boolean
  field :rating,                    type: String
  field :expectations,              type: Integer
  field :recommend,                 type: Boolean
  field :impression,                type: String
  field :press_contact,             type: Boolean
  field :improvements,              type: String
  field :answered,                  type: Boolean, default: false
  field :cancelled,                 type: Boolean, default: false
  field :viewed,                    type: Boolean, default: false
  field :viewed_at,                 type: DateTime
  field :agent_countries,           type: Array
  field :exchange_agreement_id,     type: BSON::ObjectId
  field :answered_by_account,       type: BSON::ObjectId
  field :answered_by_user,          type: BSON::ObjectId
  field :feedback_on_account,       type: BSON::ObjectId
  
  # TODO humantize the validation keys to proper wording
  validates_inclusion_of :first_exchange, :in => [true, false], :message => 'Please mark if this was your first exchange or not.'
  validates_presence_of :rating, :message => 'Please rate your exchange experience.'
  validates_presence_of :expectations, :message => 'Please fill out in how your expectations where meet.'
  validates_inclusion_of :recommend, :in => [true, false], :message => 'Please mark if you would recommend this member to other exchangers.'
  validates_presence_of :impression, :message => 'Please write a few senctaces abour your exchange experience.'
  validates_inclusion_of :press_contact, :in => [true, false], :message => 'Please mark if you would like to be contacted by the press regarding your exchange experiences.'
  validates_presence_of :improvements, :message => 'Please let us know what we can do to improve our services.'
  
  
  def self.create_feedback(exchange_agreement_id, feedback_account_id, user_account_id, user_id)
    
    agent_countries = []
    accounts = Account.find([feedback_account_id, user_account_id])
    accounts.each do |account|
      agent_countries.push(account.country_short)
    end
    
    feedback = self.new(
      exchange_agreement_id: exchange_agreement_id,
      feedback_on_account: feedback_account_id,
      answered_by_account: user_account_id,
      answered_by_user: user_id,
      agent_countries: agent_countries
    )
    
    if feedback.save!(validate: false) then
      return feedback
    end
    
    return false
    
  end
  
  
  def populate_feedback_form(form_params)
    
    self.update_attributes(
      first_exchange: form_params[:first_exchange],
      rating: form_params[:rating],
      expectations: form_params[:expectations],
      recommend: form_params[:recommend],
      impression: form_params[:impression],
      press_contact: form_params[:press_contact],
      improvements: form_params[:improvements],
      answered: true
    )
      
      
    #self.first_exchange = form_params[:first_exchange]
    #self.rating = form_params[:rating]
    #self.expectations = form_params[:expectations]
    #self.recommend = form_params[:recommend]
    #self.impression = form_params[:impression]
    #self.press_contact = form_params[:press_contact]
    #self.improvements = form_params[:improvements]
    #self.answered = true
    
    return self
    
  end
  
  def set_viewed_at
    
    self.viewed = true
    self.viewed_at = Time.now.utc
    self.save!(validate: false)
    
  end
  
end
