class Person
  include Mongoid::Document

  embedded_in :profile, :class_name => "Profile"

  field :yob,             type: Integer, default: 0
  field :gender,          type: String, default: ''
  field :occupation,      type: String, default: ''

  validates_numericality_of :yob, only_integer: true

  def age
    Time.now.year - yob
  end
end
