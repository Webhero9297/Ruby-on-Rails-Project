require 'rails_helper'

RSpec.describe Conversation, :type => :model do
  let(:account) { FactoryGirl.create(:account) }
  let(:message_status) { FactoryGirl.create(:message_status) }

  it "returns nil when the message does not exist for a given mailgun_id" do
    expect(Conversation.get_by_mailgun_id(-1)).to be_nil
  end

  it "returns the message for the given mailgun_id" do
    mailgun_id   = message_status.mailgun_id
    conversation = message_status.message.conversation
    expect(Conversation.get_by_mailgun_id(mailgun_id)).to eql(conversation)
  end

  context ".get_participants" do
    it "returns accounts for the conversation" do
      expect {
        Conversation.get_participants(nil)
      }.to_not raise_error
    end

    it "returns an empty array when receiving empty conversations" do
      expect(Conversation.get_participants([])).to be_empty
    end

    it "returns an account when receiving a conversation" do
      chat = message_status.message.conversation
      chat.participants = [account.id]
      expect(Conversation.get_participants([chat]).first).to be_an_instance_of Account
    end
  end
end
