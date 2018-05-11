# encoding: utf-8
require 'carrierwave/processing/mini_magick'

class MainPhotoUploader < CarrierWave::Uploader::Base

  # Include RMagick or MiniMagick support:
  # include CarrierWave::RMagick
  include CarrierWave::MiniMagick

  # Choose what kind of storage to use for this uploader:
  storage :file
  
  # Validates the image size, validation is done in the model
  before :cache, :capture_size_before_cache

  # Override the directory where uploaded files will be stored.
  # This is a sensible default for uploaders that are meant to be mounted:
  def store_dir
    "listings"
  end
  
  
  # Provide a default URL as a default if there hasn't been a file uploaded:
  #def default_url
  #  "/images/" + [version_name, "no-photo.png"].compact.join('_')
  #end
  
  
  # For image size validation. Fetching dimensions in uploader, validating it in model
  # callback, example here: http://goo.gl/9VGHI
  def capture_size_before_cache(new_file) 
    if model.image_width.nil? || model.image_height.nil?
      model.image_width, model.image_height = `identify -format "%wx %h" #{new_file.path}`.split(/x/).map { |dim| dim.to_i }
    end
  end
  
  
  # Process files as they are uploaded:
  process :resize_to_fit => [1024, 768]

  def full_filename(for_file = model.main_photo)
    "#{model.main_photo_path}/#{for_file}"
  end
  
  # Gallery thumb
  version :size_60 do
    process :resize_to_fill => [60, 60]
    def full_filename(for_file = model.main_photo)
      #stamp = /-([a-z0-9]*?)-/.match(for_file)
      #"#{model.listing.listing_number.downcase}-#{stamp[1]}-60.jpg"
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '60'].compact.join('-') + ext
      "#{model.main_photo_path}/#{file_name}"
    end
  end
  
  # Listings thumb
  version :size_170 do
    process :resize_and_pad => [170, 128]
    def full_filename(for_file = model.main_photo)
      #stamp = /-([a-z0-9]*?)-/.match(for_file)
      #"#{model.listing.listing_number.downcase}-#{stamp[1]}-170.jpg"
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '170'].compact.join('-') + ext
      "#{model.main_photo_path}/#{file_name}"
    end
  end

  # Listings thumb
  version :size_230 do
    process :resize_and_pad => [230, 147]
    def full_filename(for_file = model.main_photo)
      #stamp = /-([a-z0-9]*?)-/.match(for_file)
      #"#{model.listing.listing_number.downcase}-#{stamp[1]}-230.jpg"
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '230'].compact.join('-') + ext
      "#{model.main_photo_path}/#{file_name}"
    end
  end
  
  
  version :size_458 do
    process :resize_and_pad => [458, 333]
    def full_filename(for_file = model.main_photo)
      parent_name = for_file
      ext         = File.extname(parent_name)
      base_name   = parent_name.chomp(ext).chomp('-1024').chomp('-458')
      file_name = [base_name, '458'].compact.join('-') + ext
      "#{model.main_photo_path}/#{file_name}"
    end
  end

  
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg jpeg png)
  end
  
  
  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "mp-#{make_stamp}-1024.jpg" if original_filename
  end
  
  
  def make_stamp
    var = :"@#{mounted_as}_make_stamp"
    uuid = UUID.new
    stamp = uuid.generate
    model.instance_variable_get(var) or model.instance_variable_set(var, stamp.gsub('-','').downcase)
  end
  
  
end
