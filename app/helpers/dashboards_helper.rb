module DashboardsHelper
  
  ##
  # Returns the number unread conversations and feedback messages.
  # Takes an argument of true or false if the helper should send out brackets or not
  # :args: tags
  def number_of_unread_messages(tags)
    feedbacks = Feedback.not_in(read_by: [current_user.id]).count
    conversations = Conversation.all_in(participants: [current_user.account.id]).not_in(archived: [current_user.account.id]).not_in(read_by: [current_user.account.id]).count
    
    messages = feedbacks.to_i + conversations.to_i
    
    if messages != 0
      if tags
        return "(#{messages})"
      end
      
      return "#{messages}"
    end
    
    nil
  end


  def active_dashboard(active, button)
    if active == button
      return 'active'
    end

    ''
  end
  

  def messages_menu_helper(unread_messages, title=t('menu.messages'), path=conversations_url)
    if unread_messages == 0
      return link_to(content_tag('i','', class: 'icon-chevron-right') + title, path)
    end

    link_to(content_tag('i','', class: 'icon-chevron-right') + content_tag('span',unread_messages, class: 'badge badge-success unread-messages-badge') + title, path)
  end


  def unread_messages_tag(unread_messages)
    if unread_messages == 0
      return ''
    end

    content_tag('span', unread_messages, class: 'badge badge-success unread-messages-badge')
  end

end
