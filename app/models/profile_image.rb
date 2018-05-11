# encoding: utf-8
class ProfileImage
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :profile, :class_name => "Profile"

  mount_uploader :image, ProfileImageUploader

  field :caption,             type: String,   default: ''
  field :category,            type: String,   default: 'uncategorized'
  field :publicly_visible,    type: Boolean,  default: false
  field :order,               type: Integer,  default: 0

  attr_accessor :image_width, :image_height

  validates_processing_of :image

  # setting main_photo to avoid Unknown method error when checking if
  # an image is main_photo
  def main_photo
    false
  end

  def update_image(params)
    self.update_attributes(params)
    self
  end

  def self.set_order(image_list)
    index = 1
    image_list.each do |image_id|
      li = ProfileImage.where(_id: image_id).first
      next if li.nil?
      li.update_attribute(:order, index)
      index += 1
    end
  end

  def set_public
    self.update_attributes(publicly_visible: true)
  end

  def set_private
    self.update_attributes(publicly_visible: false)
  end

  class << self
    def is_public(is_signed_in)
      return where() if is_signed_in
      where(publicly_visible: true)
    end
  end

  def rotate direction
    image.versions.each do |_, uploaded_version|
      image = MiniMagick::Image.new(uploaded_version.path)
      image.rotate direction == :left ? "-90" : "90"
    end
  end
end
