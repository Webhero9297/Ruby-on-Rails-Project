require 'rails_helper'

RSpec.describe Person, :type => :model do
  it "returns the person age" do
    allow(Time).to receive_message_chain(:now, :year).and_return(2016)

    person = Person.new(yob: 1988)
    expect(person.age).to be(28)
  end
end
