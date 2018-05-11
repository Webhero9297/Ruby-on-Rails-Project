module FeedbacksHelper
  
  def available_subjects
    categories = []
    %w(bad_experience broken_link design_and_content feature_request 
      help_text intervac_international member_documents payment registration usability other).each do |cat|
      categories << [(cat=='intervac_international' ? cat.humanize : t("webfeedback.category.#{cat}")), cat.humanize]
    end
    categories
  end
  
  ##
  # Returns the number unread feedback messages.
  # Takes an argument of true or false if the helper should send out brackets or not
  # :args: tags
  def number_of_unread_feedbacks(tags)
    
    if current_user.is_agent
      unread = Feedback.not_in(read_by: [current_user.id]).for_agent(current_user.agent_profile.agent_for).count
    else
      unread = Feedback.not_in(read_by: [current_user.id]).count
    end
    
    
    if unread != 0
      if tags
        return "(#{unread})"
      end
      
      return "#{unread}"
    end
    
    return nil
  end
  
end
