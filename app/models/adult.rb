class Adult
  include Mongoid::Document
  
  embedded_in :profile, :class_name => "Profile"
  
  field :occupation,      type: String, default: ''
  
  validates_presence_of :occupation
  
end
