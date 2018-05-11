require 'rails_helper'

RSpec.describe ConversationsHelper, type: :helper do
  context "#conversation_all_or_unread?" do
    context "for 'all'" do
      it "returns true for a radio 'all' and filter 'all'" do
        expect(conversation_all_or_unread?('all', 'all')).to be_truthy
      end

      it "returns false for a radio 'all' and filter 'whatever'" do
        expect(conversation_all_or_unread?('all', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'whatever'" do
        expect(conversation_all_or_unread?('whatever', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'all'" do
        expect(conversation_all_or_unread?('whatever', 'all')).to be_falsey
      end
    end

    context "for 'unread'" do
      it "returns true for a radio 'unread' and filter 'unread'" do
        expect(conversation_all_or_unread?('unread', 'unread')).to be_truthy
      end

      it "returns false for a radio 'unread' and filter 'whatever'" do
        expect(conversation_all_or_unread?('unread', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'whatever'" do
        expect(conversation_all_or_unread?('whatever', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'unread'" do
        expect(conversation_all_or_unread?('whatever', 'unread')).to be_falsey
      end
    end
  end

  context "#conversation_last_or_first?" do
    context "for 'last'" do
      it "returns true for a radio 'last' and filter 'last'" do
        expect(conversation_last_or_first?('last', 'last')).to be_truthy
      end

      it "returns false for a radio 'last' and filter 'whatever'" do
        expect(conversation_last_or_first?('last', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'whatever'" do
        expect(conversation_last_or_first?('whatever', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'last'" do
        expect(conversation_last_or_first?('whatever', 'last')).to be_falsey
      end
    end

    context "for 'first'" do
      it "returns true for a radio 'first' and filter 'first'" do
        expect(conversation_last_or_first?('first', 'first')).to be_truthy
      end

      it "returns false for a radio 'first' and filter 'whatever'" do
        expect(conversation_last_or_first?('first', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'whatever'" do
        expect(conversation_last_or_first?('whatever', 'whatever')).to be_falsey
      end

      it "returns false for a radio 'whatever' and filter 'first'" do
        expect(conversation_last_or_first?('whatever', 'first')).to be_falsey
      end
    end
  end
end
