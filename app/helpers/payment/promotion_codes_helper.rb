module Payment::PromotionCodesHelper

  # FIXME: write a test and refactor
  def has_promotion_code(price_plans)

    has_codes = false

    price_plans.each do |price_plan|
      price_plan.promotion_codes.each do |promotion_code|
        has_codes = true
      end
    end

    return has_codes
  end

end
