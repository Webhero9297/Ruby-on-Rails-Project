class Igettext
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  
  field :msgid,     type: String
  field :location,  type: String
  field :added,     type: Boolean, default: false
  
  #index :msgid, :unique
  
  
  def self.remove_added_translation(key)
    Igettext.where(msgid: key).delete_all
  end
end
