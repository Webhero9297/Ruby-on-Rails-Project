class Attachment
  include Mongoid::Document
  include Mongoid::Timestamps
  #include ActiveModel::ForbiddenAttributesProtection
  embedded_in :message, :class_name => "Message"
  
  mount_uploader :file, AttachmentUploader
  
end
