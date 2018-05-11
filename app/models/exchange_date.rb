# encoding: utf-8
class ExchangeDate
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :listing, :class_name => "Listing"
  
  field :note,              type: String
  field :earliest_date,     type: Time
  field :latest_date,       type: Time
  field :length_of_stay,    type: Integer, default: 2
  field :periodicity,       type: String, default: 'weeks'
  
  validates_presence_of :earliest_date
  validates_presence_of :latest_date
  validate :latest_date_must_be_higher_than_earliest
  validates_numericality_of :length_of_stay, :greater_than_or_equal_to => 1, :message => I18n.t('error.minimum_stay_1_day')
  
  def latest_date_must_be_higher_than_earliest
    return if earliest_date.blank? or latest_date.blank?
    if earliest_date > latest_date
      errors.add(:earliest_date, I18n.t('error.require_earlier_than_latest_date'))
    end
  end
  
  def self.get_latest_period
    self.first(sort: [[ :latest_date, :desc ]])
  end
  
  def self.get_all_valid_periods
    self.where(:latest_date.gt => Time.now.utc).asc(:earliest_date)
  end

  def self.get_longest_duration
    periods = {'days' => 1, 'weeks' => 7, 'months' => 31}
    longest = 0
    longest_term = nil
    self.all.each do |term|
      total = periods[term.periodicity] * term.length_of_stay
      if total > longest
        longest = total
        longest_term = term
      end
    end
    return "#{longest_term.length_of_stay} #{longest_term.periodicity}"
  end
  
end
