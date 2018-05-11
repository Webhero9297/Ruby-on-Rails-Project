class Pet
  include Mongoid::Document
  
  embedded_in :profile, :class_name => "Profile"
  
  field :kind,        type: String, default: ''
  
  validates_length_of :kind, :minimum => 2, :message => 'You must enter what type of pet you have.'
  
end
