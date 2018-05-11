# encoding: utf-8
require 'carrierwave/processing/mini_magick'

class AgentImageUploader < CarrierWave::Uploader::Base

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
    "agents/#{model.agent_profile.user.account.account_number.to_s}/"
  end

  # Provide a default URL as a default if there hasn't been a file uploaded:
  # def default_url
  #   "/images/fallback/" + [version_name, "default.png"].compact.join('_')
  # end

  # For image size validation. Fetching dimensions in uploader, validating it in model
  # callback, example here: http://goo.gl/9VGHI
  def capture_size_before_cache(new_file) 
    if model.image_width.nil? || model.image_height.nil?
      model.image_width, model.image_height = `identify -format "%wx %h" #{new_file.path}`.split(/x/).map { |dim| dim.to_i }
    end
  end

  
  # Process files as they are uploaded:
  process :resize_to_fit => [640, 480]
  
  
  # Creates the profile size
  version :size_150 do
    process :resize_to_fill => [150, 140]
    def full_filename(for_file = model.logo.file) 
      "#{model.agent_profile.user.name.sluggerize}-150.jpg"
    end
  end
  
  
  # Add a white list of extensions which are allowed to be uploaded.
  # For images you might use something like this:
  def extension_white_list
    %w(jpg)
  end
  
  # Override the filename of the uploaded files:
  # Avoid using model.id or version_name here, see uploader/store.rb for details.
  def filename
    "#{model.agent_profile.user.name.sluggerize}-640.jpg" if original_filename
  end

end