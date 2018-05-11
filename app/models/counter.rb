class Counter
  include Mongoid::Document
  
  field :next,            type: Integer, default: 1000000
  
  validates_uniqueness_of :next

  
  def self.get_next
    counter = Counter.first
    if counter.nil?
      counter = Counter.create
    end
    counter.inc(:next, 1)
    return counter.next
  end
  
end
