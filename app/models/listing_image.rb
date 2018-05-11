# encoding: utf-8
class ListingImage
  include Mongoid::Document
  include Mongoid::Timestamps
  include ActiveModel::ForbiddenAttributesProtection
  embedded_in :listing, :class_name => "Listing"

  mount_uploader :image, ListingImageUploader

  field :caption,             type: String,   default: ''
  field :category,            type: String,   default: 'uncategorized'
  field :publicly_visible,    type: Boolean,  default: false
  field :main_photo,          type: Boolean,  default: false
  field :order,               type: Integer,  default: 0
  field :path,                type: String,   default: ''

  attr_accessor :image_width, :image_height

  # Validation of image sizes has been removed due to a Intervac BD decision
  validates_processing_of :image

  after_save :validate_listing
  after_destroy :validate_listing
  before_create :set_path

  def update_image(params)
    self.update_attributes(params)

    if params[:main_photo] == '1'
      self.set_as_main
    end

    self
  end

  ##
  # Updates the caption for the image and if it is the main photo the caption is set on that as well.
  def update_caption(caption)
    self.update_attribute(:caption, caption)

    if self.main_photo
      self.listing.set_main_photo_caption(caption)
    end

    self
  end

  ##
  # Specific method used by listing main photo to propagate caption
  def self.set_caption_main_photo(caption)
    photo = self.where(main_photo: true).first

    if photo
      photo.set(:caption, caption)
    else
      Rails.logger.error("Tried to propagate caption to main photo but it does not exist")
    end
  end

  def set_as_main
    filename = File.basename(self.image.to_s)
    Listing.collection.update(
      { "_id" => self.listing.id },
      {
          '$set' => {
              "main_photo_caption" => self.caption,
              'main_photo' => filename,
              'path' => self.path
          }
      },
    )

    self.listing.listing_images.where(main_photo: true).each do |image|
      image.update_attributes(main_photo: false, order: 1)
    end

    self.update_attributes(main_photo: true, publicly_visible: true, order: 0)
  end

  def self.set_order(image_list)
    index = 1
    image_list.each do |image_id|
      li = ListingImage.where(_id: image_id).first
      next if li.nil?
      li.update_attribute(:order, index)
      index += 1
    end
  end

  def set_public
    self.update_attributes(publicly_visible: true)
  end

  def set_private
    self.update_attributes(publicly_visible: false, main_photo: false)
  end

  class << self
    def is_public(is_signed_in)
      return where() if is_signed_in
      where(publicly_visible: true)
    end

    def has_image
      where(:image.exists => true)
    end

    def get_by_category(categories)
      where(:category.in => categories)
    end

    def no_main_photo
      where(:main_photo => false)
    end
  end

  def rotate direction
    image.versions.each do |_, uploaded_version|
      image = MiniMagick::Image.new(uploaded_version.path)
      begin
        image.rotate direction == :left ? "-90" : "90"
      rescue => e
        Rails.logger.error("Could not rotate image #{uploaded_version.path}: #{e}")
      end
    end
  end

  protected

  def full_path
    image.path
  end

  def validate_listing
    # Make sure the listing is validated after we saved or removed an image
    self.listing.save
  end

  def set_path
    self.path = "#{self.listing.country_code.downcase}/#{self.listing.listing_number.downcase}"
  end

  default_scope where(:image.exists => true)
end
