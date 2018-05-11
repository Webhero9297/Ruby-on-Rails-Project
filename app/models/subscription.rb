class Subscription
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  embedded_in :account, :class_name => 'Account'
  
  field :base_price,      type: Float, default: nil
  field :renewal_price,   type: Float, default: nil
  field :name,            type: String, default: nil
  field :duration,        type: Integer, default: 1
  field :periodicity,     type: String, default: 'years'
  field :kind,            type: String, default: 'paid'
  field :promotion_code,  type: String, default: nil
  field :currency,        type: String, default: nil
  field :renewal,         type: Boolean, default: false
  field :upgrade,         type: Boolean, default: false
  field :active,          type: Boolean, default: false
  field :expires_at,      type: DateTime, default: nil
  field :order_id,        type: BSON::ObjectId, default: nil
  field :order_number,    type: String, default: nil
    
  def is_trial?
    if self.kind == 'free'
      return true
    end
    
    false
  end

  def activate
    self.account.subscriptions.each do |subscription|
      subscription.set(:active, false)
    end
    self.active = true
    self.save
    self.propagate_expires_at
    self.propagate_open_past_listing
  end

  def prolong(expires_at)
    self.set(:expires_at, expires_at.to_time)
    self.propagate_expires_at
  end

  protected

  def set_expires_at_on_account(account, expires_at)
    account.set(:current_expires_at, expires_at.to_time)
  end

  def set_expires_at_on_listing(listing, expires_at)
    listing.set(:account_expires_at, expires_at.to_time)
  end

  def propagate_expires_at
    set_expires_at_on_account(self.account, self.expires_at)

    self.account.listings.each do |listing|
      set_expires_at_on_listing(listing, self.expires_at)
    end
  end

  def propagate_open_past_listing
    self.account.listings.each do |listing|
      listing.set(:open_past_listing, nil)
    end
  end
end
