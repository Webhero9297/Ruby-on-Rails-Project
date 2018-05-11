class PromotionCode
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection

  embedded_in :price_plan, :class_name => 'PricePlan'

  field :code,              type: String
  field :discounted_price,  type: Integer
  field :limit,             type: Integer, default: nil
  field :usage,             type: Integer, default: 0
  field :description,       type: String
  field :end_date,          type: DateTime
  field :archived,          type: Boolean, default: false

  validates_presence_of :discounted_price
  # validates_uniqueness_of :code, :case_sensitive => false
  # validate :uniqueness_of_code

  before_save :upcase_code

  def redeemable?
    !self.has_expired && self.has_usage && !self.archived
  end

  def archive
    self.set(:archived, true)
  end

  # increments the promotion code usage with 1
  def add_usage
    self.inc(:usage, 1)
  end

  # Returns TRUE if the code is still usable
  def has_usage
    if self.limit.blank?
      return true
    end
    if self.usage >= self.limit
      return false
    end

    return true
  end

  # Returns TRUE if the promotion code has expired
  def has_expired
    if self.end_date and self.end_date < Time.now.utc
      return true
    end

    return false
  end

  protected
  def upcase_code
    self.code = self.code.upcase
  end
end
