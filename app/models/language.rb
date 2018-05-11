class Language
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  field :msgid,           type: String
  field :short,           type: String
end
