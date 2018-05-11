# encoding: utf-8
class Environment
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  field :msgid,           type: String
  field :short,           type: String
  field :selectable,      type: Boolean, default: true
  
  scope :selectable, where(selectable: true)
  
  # TODO check if really needed
  def self.get_settings
    
    settings = []
    environments = self.only(:msgid, :short).limit(20).to_a
    
    environments.each do |setting|
      settings.push([ ApplicationController.helpers.t(setting.msgid), setting.short])
    end
    
    return settings.sort
  end

end
