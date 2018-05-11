class PricePlan
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :country, :class_name => 'Country'
  embeds_many :promotion_codes, :class_name => 'PromotionCode'
  
  field :ref_id,          type: String, default: nil
  field :base_price,      type: Float, default: nil
  field :renewal_price,   type: Float, default: nil
  field :name,            type: String, default: nil
  field :duration,        type: Integer, default: 1
  field :periodicity,     type: String, default: 'years'
  field :kind,            type: String, default: 'paid'
  field :active,          type: Boolean, default: false
  field :default,         type: Boolean, default: false
  field :shared_by,       type: Array, default: []
  field :shared_id,       type: BSON::ObjectId, default: nil

  validates :base_price, :numericality => true
  validates :renewal_price, :numericality => true


  def is_paid_plan?

    if self.kind != 'paid' then
      return false
    end

    return true
  end


  def mark_promotion_code_for_usage(order)

    # Check if promotion code is used or not. If no promotion code is used, return directly
    if order.promotion_code.nil? or order.promotion_code.blank?
      return
    end

    promotion_code = self.promotion_codes.where(code: order.promotion_code).first
    promotion_code.add_usage
  end

  # Fetches and returns the a promotion code document
  def get_promotion_code(promotion_code)

    promotion_code = promotion_code.upcase
    code = self.promotion_codes.where(:code => promotion_code).first
    return code
  end


  def self.reset_ids(attributes)
      attributes.each do |key, value|
          if key == "_id" and value.is_a?(BSON::ObjectId)
              attributes[key] = BSON::ObjectId.new
          elsif value.is_a?(Hash) or value.is_a?(Array)
              attributes[key] = reset_ids(value)
          end        
      end
      attributes
  end


  def self.set_as_shared(price_plan, countries)
    
    if price_plan.shared_id == nil
      shared_id = BSON::ObjectId.new
      price_plan.set(:shared_by, countries.to_a)
      price_plan.set(:shared_id, shared_id)
    end
    
    countries = Country.find(countries.to_a)
    countries.each do |country|
      if price_plan.country.id != country.id
        if not country.price_plans.where(shared_id: price_plan.shared_id).exists?
          country_price_plan = country.price_plans.new(PricePlan.reset_ids(price_plan.attributes))
          country_price_plan.save
        end
      end
    end

  end


  def self.update_shared_plans(price_plan)

    countries = Country.find(price_plan.shared_by)
    shared_id = price_plan.shared_id

    countries.each do |country|
      country_price_plan = country.price_plans.where(shared_id: shared_id).first()
      country_price_plan.update_attributes(
        base_price:     price_plan.base_price,
        renewal_price:  price_plan.renewal_price,
        name:           price_plan.name,
        duration:       price_plan.duration,
        periodicity:    price_plan.periodicity,
        kind:           price_plan.kind,
        active:         price_plan.active,
        default:        price_plan.default
      )
    end

  end

end
