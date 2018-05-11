# encoding: utf-8
class ContactRestriction
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :account, :class_name => "Account"

  field :added_as_favorite, type: Boolean, default: false

end