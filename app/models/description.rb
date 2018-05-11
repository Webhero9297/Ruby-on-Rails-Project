class Description
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :profile, :class_name => "Profile"
  
  field :text,        type: String,   default: ''
  field :visible,     type: Boolean,  default: false
end
