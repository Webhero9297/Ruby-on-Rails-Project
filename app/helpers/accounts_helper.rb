# encoding: UTF-8
module AccountsHelper

  def switch_to_user_link(destination, return_destination, dashboard, return_dashboard, user_id, opt = {})

    if opt[:text].nil?
      link_text = 'Switch to user'
    else
      link_text = opt[:text]
    end

    if opt[:class].nil?
      link_class = 'btn btn-small'
    else
      link_class = opt[:class]
    end

    link_to(link_text, "/switch_user?dt=#{destination}&rdt=#{return_destination}&db=#{dashboard}&rdb=#{return_dashboard}&scope_identifier=user_#{user_id}", class: link_class)
  end


  def switch_to_management_link
    link_to('Switch Back', "/switch_user?dt=#{session[:return_destination]}&rdb=#{session[:return_dashboard]}&mnt=true&scope_identifier=user_#{session[:management_user_id]}", class: 'link-switch')
  end


  ##
  # Prints out a label for showing account status for active or expired, takes a bool.
  def account_status_badge(has_expired)
    if has_expired
      return content_tag('span', t('global.expired'), class: 'badge badge-important')
    end

    content_tag('span', t('global.active'), class: 'badge badge-success')
  end

  def custom_account_status_badge(badge, title)
    content_tag('span', t("global.#{badge}"), class: 'badge badge-important', title: title)
  end

end
