module Member::ListingsHelper
  
  def print_icon(active_listing, error, error_extra='')
    if active_listing.errors.messages.has_key?(error)
      return error_extra
    end
    return content_tag(:span, content_tag('i','', class: 'icon-ok-sign icon-white'), class: 'label label-success yes-no')
  end


  def selected_placeholder(selected_placeholder, placeholder)
    if selected_placeholder == placeholder
      return true
    end
    false
  end

end
