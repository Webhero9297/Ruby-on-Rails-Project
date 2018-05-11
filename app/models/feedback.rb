class Feedback
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  field :account_id,        type: BSON::ObjectId, default: ''
  field :account_number,    type: Integer, default: nil
  field :member_number,     type: String, default: ''
  field :as_guest,          type: Boolean, default: false
  field :name,              type: String, default: nil
  field :email,             type: String, default: nil
  field :subject,           type: String, default: nil
  field :message,           type: String, default: nil
  field :page,              type: String, default: ''
  field :country_short,     type: String, default: ''
  field :browser_agent,     type: String, default: ''
  field :read_by,           type: Array, default: []

  validates_presence_of :subject, :message => 'Please choose a subject'
  validates_presence_of :country_short, :message => 'Please specify your country'
  validates_presence_of :name, :message => 'You must enter your name'
  validates_length_of :message, allow_blank: false, minimum: 8, maximum: 4096, :message => 'Please write a short message'
  validates_format_of :email, with: /\A[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]+\z/, allow_blank: false, minimum: 3, maximum: 128, :message => 'You must enter your email address'
  validates_format_of :page, :with => URI::DEFAULT_PARSER.regexp[:ABS_URI], :if => :page_filled?, :message => 'You must provide a valid url of the page you want to report.'

  def page_filled?
    !page.blank?
  end

  def mark_as_read(user_id)
    self.add_to_set(:read_by, user_id)
  end

  def self.build_new_feedback(params, browser_agent)
    self.new(
      as_guest: params[:as_guest],
      account_id: params[:account_id],
      account_number: params[:account_number],
      name: params[:name],
      email: params[:email],
      subject: params[:subject],
      message: params[:message],
      page: params[:page],
      country_short: params[:country_short],
      browser_agent: browser_agent
    )
  end

  def self.for_agent(agent_for)
    if agent_for.nil? or agent_for.empty?
      return []
    end

    countries = []

    agent_for.each do |country|
      countries.push(country['short'])
    end

    self.any_in(country_short: countries)
  end

  def self.notify_admins_and_agents(feedback)
    agents = User.where(roles: 'agent').and('agent_profile.agent_for.short' => feedback[:country_short].upcase)

    # FIXME: Yes, it is hard coded. We should create a way to use configuration
    # files or environment variables (dotenv?)
    admins = ["the-board@intervac.org", "webmaster@intervac.com"]

    emails = agents.map(&:email) + admins
    NotificationMailer.service_feedback(feedback, emails).deliver
  end
end
