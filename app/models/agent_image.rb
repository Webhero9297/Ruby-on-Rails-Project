# encoding: utf-8
class AgentImage
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :agent_profile, :class_name => "AgentProfile"

  mount_uploader :image, AgentImageUploader
  field :caption, type: String, default: ''

  attr_accessor :image_width, :image_height

  #validates_presence_of :image
  #validates_integrity_of :image
  validates_processing_of :image
  #validate :check_image_dimensions

  def check_image_dimensions
    unless self.image_width.nil? || self.image_height.nil?
      errors.add(:image, I18n.t('error.image_smaller_than_640_480')) if self.image_width < 640 || image_height < 480
    end
  end
end
