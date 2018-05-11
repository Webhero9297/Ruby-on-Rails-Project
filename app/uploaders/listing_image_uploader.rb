# encoding: utf-8
require 'carrierwave/processing/mini_magick'

class ListingImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::MiniMagick

  storage :file

  before :cache, :capture_size_before_cache

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "listings"
  end

  # For image size validation. Fetching dimensions in uploader, validating it in model
  # callback, example here: http://goo.gl/9VGHI
  def capture_size_before_cache(new_file)
    if model.image_width.nil? || model.image_height.nil?
      model.image_width, model.image_height = `identify -format "%wx %h" #{new_file.path}`.split(/x/).map { |dim| dim.to_i }
    end
  end

  # Process files as they are uploaded:
  process :resize_to_fit => [1024, 768]

  def full_filename(for_file = model.listing.listing_images.image)
    "#{model.path}/#{for_file}"
  end

  # Gallery thumb
  version :size_60 do
    process :resize_to_fill => [60, 60]
    def full_filename(for_file = model.listing.listing_images.image)
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '60'].compact.join('-') + ext
      "#{model.path}/#{file_name}"
    end
  end

  # Listings thumb
  version :size_170 do
    process :resize_and_pad => [170, 128]
    def full_filename(for_file = model.listing.listing_images.image)
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '170'].compact.join('-') + ext
      "#{model.path}/#{file_name}"
    end
  end

  # Listings thumb
  version :size_230 do
    process :resize_and_pad => [230, 147]
    def full_filename(for_file = model.listing.listing_images.image)
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '230'].compact.join('-') + ext
      "#{model.path}/#{file_name}"
    end
  end

  version :size_458 do
    process :resize_and_pad => [458, 333]
    def full_filename(for_file = model.listing.listing_images.image)
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '458'].compact.join('-') + ext
      "#{model.path}/#{file_name}"
    end
  end

  def extension_white_list
    %w(jpg jpeg png)
  end

  def filename
    "#{model.listing.listing_number.downcase}-#{make_stamp}-1024.jpg" if original_filename
  end

  def make_stamp
    var = :"@#{mounted_as}_make_stamp"
    uuid = UUID.new
    stamp = uuid.generate
    model.instance_variable_get(var) or model.instance_variable_set(var, stamp.gsub('-','').downcase)
  end
end
