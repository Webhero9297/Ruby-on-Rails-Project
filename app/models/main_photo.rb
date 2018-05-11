# encoding: utf-8
class MainPhoto
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :listing, :class_name => "Listing"
  
  mount_uploader :image, MainPhotoUploader
  
  field :caption,             type: String,   default: ''
  field :path,                type: String,   default: ''
  
  attr_accessor :image_width, :image_height
  attr_accessible :image_cache
    
  #validates_integrity_of :image
  #validates_presence_of :image, message: "Upload an image please"
  validates_processing_of :image
  # Validation of image sizes has been removed due to a Intervac BD decision
  
  before_save :set_path
    
  class << self

    def has_image
      where(:image.exists => true)
    end

  end
  
  
  protected
  def set_path
    self.path = "SE"##{self.listing.country_code.downcase}/#{self.listing.listing_number.downcase}"
  end  
  
  #default_scope where(:image.exists => true)
end
