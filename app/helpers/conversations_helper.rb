module ConversationsHelper
  def message_date(msg_date)
    return if msg_date.nil?

    zone = ActiveSupport::TimeZone.new("UTC")
    unless session[:time_zone].blank?
      zone = ActiveSupport::TimeZone.new(session[:time_zone])
    end

    msg_date.in_time_zone(zone).strftime("%B %d, %Y - %H:%M")
  end

  ##
  # Returns the proper class for the conversation state
  def conversation_state(conversation, user)
    if conversation.read_by.include?(user.account_id)
      return 'conversation-read'
    end

    'conversation-unread'
  end


  ##
  # Returns the number unread feedback messages.
  # Takes an argument of true or false if the helper should send out brackets or not
  # :args: tags
  def number_of_unread_conversations(tags)
    if current_user.is_agent
      unread = Conversation.where(:kind.in => ['member_to_agent', 'agent_to_member']).where(participants: current_user.account.id).not_in(archived: [current_user.account.id]).not_in(read_by: [current_user.account.id]).count
    else
      unread = Conversation.where(participants: current_user.account.id).not_in(archived: [current_user.account.id]).not_in(read_by: [current_user.account.id]).count
    end

    if unread != 0
      if tags
        return "(#{unread})"
      end

      return "#{unread}"
    end

    return nil
  end


  def conversation_all_or_unread?(radio, filter)
    if radio == 'all' and filter == 'all'
      return true
    end

    if radio == 'unread' and filter == 'unread'
      return true
    end

    false
  end


  def conversation_last_or_first?(radio, order)
    if radio == 'last' and order == 'last'
      return true
    end

    if radio == 'first' and order == 'first'
      return true
    end

    false
  end

  def invalid_account_and_conversation?(user, conversation)
    from_account = user.account
    to_account   = conversation.get_conversation_partner(user.account_id)

    # Sometimes we have just 1 participant
    #
    # we will consider the account<->conversation relation as invalid
    # when there is no `to_account`
    return true unless to_account

    has_expired(from_account) ||
      has_expired(to_account) ||
      to_account.terminated
  end
end
